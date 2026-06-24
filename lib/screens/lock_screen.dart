import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lock_service.dart';

class LockScreen extends StatefulWidget {
  final Function(bool) onUnlocked;
  final String language;
  final bool isDarkMode;

  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.language = 'bn',
    this.isDarkMode = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final LockService _lockService = LockService();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  String _pin = '';
  String _errorMessage = '';
  String _lockType = 'pin';
  bool _hasBiometric = false;
  int _attempts = 0;
  bool _isLockedOut = false;

  // ===== LOCALIZATION =====
  final Map<String, Map<String, String>> _texts = {
    'bn': {
      'app_name': 'আমার হিসাব',
      'enter_pin': 'অ্যাপ খুলতে পিন লিখুন',
      'wrong_pin': 'ভুল পিন! আবার চেষ্টা করুন',
      'attempts_left': 'বার বাকি',
      'too_many_attempts': 'অনেকবার ভুল হয়েছে। ৩০ সেকেন্ড অপেক্ষা করুন',
      'use_fingerprint': 'ফিঙ্গারপ্রিন্ট ব্যবহার করুন',
      'forgot_pin': 'পিন ভুলে গেছেন? রিসেট করুন',
      'no_security_question': 'কোনো নিরাপত্তা প্রশ্ন সেট করা নেই। অ্যাপ রি-ইন্সটল করে আবার চেষ্টা করুন।',
      'reset_pin': 'পিন রিসেট',
      'answer_question': 'নিরাপত্তা প্রশ্নের উত্তর দিন',
      'verify': 'যাচাই করুন',
      'cancel': 'বাতিল',
      'set_new_pin': 'নতুন পিন সেট করুন',
      'new_pin': 'নতুন পিন',
      'confirm_pin': 'পিন নিশ্চিত করুন',
      'save': 'সেভ করুন',
      'pin_must_be_4_digits': 'পিন ৪ ডিজিট হতে হবে',
      'pin_mismatch': 'পিন মেলেনি',
      'pin_reset_success': 'পিন সফলভাবে রিসেট হয়েছে',
      'wrong_answer': 'উত্তর সঠিক নয়',
    },
    'en': {
      'app_name': 'My Accounting',
      'enter_pin': 'Enter PIN to unlock',
      'wrong_pin': 'Wrong PIN! Try again',
      'attempts_left': 'attempts left',
      'too_many_attempts': 'Too many attempts. Wait 30 seconds',
      'use_fingerprint': 'Use Fingerprint',
      'forgot_pin': 'Forgot PIN? Reset',
      'no_security_question': 'No security question set. Please reinstall the app.',
      'reset_pin': 'Reset PIN',
      'answer_question': 'Answer security question',
      'verify': 'Verify',
      'cancel': 'Cancel',
      'set_new_pin': 'Set New PIN',
      'new_pin': 'New PIN',
      'confirm_pin': 'Confirm PIN',
      'save': 'Save',
      'pin_must_be_4_digits': 'PIN must be 4 digits',
      'pin_mismatch': 'PIN mismatch',
      'pin_reset_success': 'PIN reset successfully',
      'wrong_answer': 'Wrong answer',
    },
    'ar': {
      'app_name': 'محاسبتي',
      'enter_pin': 'أدخل الرمز لفتح التطبيق',
      'wrong_pin': 'رمز خاطئ! حاول مرة أخرى',
      'attempts_left': 'محاولات متبقية',
      'too_many_attempts': 'محاولات كثيرة خاطئة. انتظر 30 ثانية',
      'use_fingerprint': 'استخدم بصمة الإصبع',
      'forgot_pin': 'نسيت الرمز؟ إعادة تعيين',
      'no_security_question': 'لم يتم تعيين سؤال أمان. يرجى إعادة تثبيت التطبيق.',
      'reset_pin': 'إعادة تعيين الرمز',
      'answer_question': 'أجب عن سؤال الأمان',
      'verify': 'تحقق',
      'cancel': 'إلغاء',
      'set_new_pin': 'تعيين رمز جديد',
      'new_pin': 'رمز جديد',
      'confirm_pin': 'تأكيد الرمز',
      'save': 'حفظ',
      'pin_must_be_4_digits': 'يجب أن يكون الرمز 4 أرقام',
      'pin_mismatch': 'الرمز غير متطابق',
      'pin_reset_success': 'تم إعادة تعيين الرمز بنجاح',
      'wrong_answer': 'إجابة خاطئة',
    },
  };

  String getText(String key) {
    final lang = widget.language;
    return _texts[lang]?[key] ?? _texts['en']?[key] ?? key;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===== NUMPAD =====
  Widget _buildNumpad() {
    final double buttonSize = MediaQuery.of(context).size.width / 5.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNumpadRow(['1', '2', '3'], buttonSize),
        const SizedBox(height: 12),
        _buildNumpadRow(['4', '5', '6'], buttonSize),
        const SizedBox(height: 12),
        _buildNumpadRow(['7', '8', '9'], buttonSize),
        const SizedBox(height: 12),
        _buildNumpadRowWithSpecial(buttonSize),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> numbers, double size) {
    return Row(
      children: numbers.map((n) => Expanded(child: _buildNumpadButton(n, size))).toList(),
    );
  }

  Widget _buildNumpadRowWithSpecial(double size) {
    return Row(
      children: [
        if (_hasBiometric)
          Expanded(child: _buildFingerprintButton(size))
        else
          Expanded(child: Container()),
        Expanded(child: _buildNumpadButton('0', size)),
        Expanded(child: _buildDeleteButton(size)),
      ],
    );
  }

  Widget _buildNumpadButton(String number, double size) {
    return SizedBox(
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLockedOut ? null : () => _onPinEntered(_pin + number),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.blueGrey.shade800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(double size) {
    return SizedBox(
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLockedOut
              ? null
              : () {
                  if (_pin.isNotEmpty) {
                    final newPin = _pin.substring(0, _pin.length - 1);
                    _pinController.text = newPin;
                    setState(() {
                      _pin = newPin;
                      _errorMessage = '';
                    });
                  }
                },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade100, Colors.red.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.backspace_outlined, size: size * 0.4, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintButton(double size) {
    return SizedBox(
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLockedOut ? null : _attemptBiometric,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.fingerprint, size: size * 0.5, color: Colors.blue),
            ),
          ),
        ),
      ),
    );
  }

  // ===== LIFE CYCLE =====
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsAndAuthenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lockType != 'pin') {
      _attemptBiometric();
    }
  }

  Future<void> _loadSettingsAndAuthenticate() async {
    try {
      _hasBiometric = await _lockService.isBiometricAvailable();
      _lockType = await _lockService.getLockType();
      if (_lockType.isEmpty) _lockType = 'pin';

      if (_lockType == 'biometric' || _lockType == 'both') {
        _attemptBiometric();
      }
      if (_lockType == 'pin' || _lockType == 'both') {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _pinFocusNode.requestFocus();
        });
      }
    } catch (e) {
      debugPrint("Error loading lock settings: $e");
    }
    if (mounted) setState(() {});
  }

  Future<void> _attemptBiometric() async {
    if (!_hasBiometric) return;
    final reason = getText('enter_pin');
    final authenticated = await _lockService.authenticateWithBiometric(reason: reason);
    if (authenticated && mounted) {
      widget.onUnlocked(true);
    }
  }

  void _onPinEntered(String value) {
    if (_isLockedOut) return;
    if (value.length == 4) {
      _verifyPin(value);
    }
    setState(() {
      _pin = value;
      _errorMessage = '';
    });
  }

  void _verifyPin(String enteredPin) async {
    final isValid = await _lockService.verifyPin(enteredPin);
    if (isValid) {
      if (mounted) widget.onUnlocked(true);
    } else {
      if (!mounted) return;
      setState(() {
        _attempts++;
        _pin = '';
        _pinController.clear();
        if (_attempts >= 5) {
          _isLockedOut = true;
          _errorMessage = getText('too_many_attempts');
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) {
              setState(() {
                _isLockedOut = false;
                _attempts = 0;
                _errorMessage = '';
              });
            }
          });
        } else {
          _errorMessage = '${getText('wrong_pin')} (${5 - _attempts} ${getText('attempts_left')})';
        }
      });
    }
  }

  void _onTextChanged(String value) {
    if (_isLockedOut) return;
    if (value.length > 4) {
      _pinController.text = value.substring(0, 4);
      return;
    }
    setState(() {
      _pin = value;
      _errorMessage = '';
    });
    if (value.length == 4) {
      _verifyPin(value);
    }
  }

  // ===== FORGOT PIN DIALOG =====
  Future<void> _showForgotPinDialog() async {
    final question = await _lockService.getSecurityQuestion();
    if (question == null || question.isEmpty) {
      _showSnackBar(getText('no_security_question'));
      return;
    }

    final TextEditingController answerCtrl = TextEditingController();
    bool isDialogOpen = true;

    try {
      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lock_reset, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text(getText('reset_pin'), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getText('answer_question'),
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      question,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: answerCtrl,
                    obscureText: true,
                    obscuringCharacter: '●',
                    enableInteractiveSelection: false,
                    autocorrect: false,
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade800),
                    decoration: InputDecoration(
                      labelText: getText('verify'),
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (isDialogOpen) {
                    isDialogOpen = false;
                    Navigator.pop(context, false);
                    Future.delayed(const Duration(milliseconds: 100), () => answerCtrl.dispose());
                  }
                },
                child: Text(getText('cancel'), style: TextStyle(color: Colors.grey.shade700)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final input = answerCtrl.text.trim();
                  if (input.isEmpty) {
                    _showSnackBar('Please enter your answer');
                    return;
                  }
                  final isValid = await _lockService.verifySecurityAnswer(input);
                  if (!mounted || !isDialogOpen) return;

                  if (isValid) {
                    isDialogOpen = false;
                    Navigator.pop(context, true); // প্রথমে সেফলি ডায়ালগ বন্ধ করা হলো
                    Future.delayed(const Duration(milliseconds: 100), () => answerCtrl.dispose());
                  } else {
                    _showSnackBar(getText('wrong_answer'));
                    answerCtrl.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(getText('verify')),
              ),
            ],
          );
        },
      );

      // সিক্রেট আনসার সফল হলে ১৫০ মিলি-সেকেন্ড অপেক্ষা করে নতুন পিন সেটআপ ডায়ালগ ওপেন হবে (রেড স্ক্রিন আটকাতে)
      if (result == true && mounted) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _showNewPinDialog();
        });
      }
    } catch (e) {
      debugPrint('Error in _showForgotPinDialog: $e');
      answerCtrl.dispose();
    }
  }

  // ===== NEW PIN DIALOG =====
  Future<void> _showNewPinDialog() async {
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    bool isDialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          // ফিক্সড: টাইটেল ডিরেক্ট উইজেট দিয়ে রেন্ডার করা হলো (আগের TextStyle বাগ রিমুভড)
          title: Text(
            getText('set_new_pin'),
            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: getText('new_pin'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: getText('confirm_pin'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (isDialogOpen) {
                  isDialogOpen = false;
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    newPinCtrl.dispose();
                    confirmPinCtrl.dispose();
                  });
                }
              },
              child: Text(getText('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPinCtrl.text.length != 4) {
                  _showSnackBar(getText('pin_must_be_4_digits'));
                  return;
                }
                if (newPinCtrl.text != confirmPinCtrl.text) {
                  _showSnackBar(getText('pin_mismatch'));
                  return;
                }

                await _lockService.savePin(newPinCtrl.text);
                await _lockService.setLockEnabled(true);

                if (!mounted || !isDialogOpen) return;

                isDialogOpen = false;
                Navigator.pop(context); // ডায়ালগ পপ করা হলো

                _showSnackBar(getText('pin_reset_success'));

                setState(() {
                  _pin = '';
                  _pinController.clear();
                });

                // ডায়ালগ বন্ধ হওয়ার পর মেমোরি থেকে সেফলি কন্ট্রোলার রিমুভ করা হলো
                Future.delayed(const Duration(milliseconds: 100), () {
                  newPinCtrl.dispose();
                  confirmPinCtrl.dispose();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(getText('save')),
            ),
          ],
        );
      },
    );
  }

  // ===== MAIN BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.purple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  getText('app_name'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getText('enter_pin'),
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pin.length > index
                            ? Colors.blue.shade700
                            : Colors.grey.shade300,
                        boxShadow: _pin.length > index
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 0,
                    child: TextField(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      onChanged: _onTextChanged,
                      autofocus: true,
                      enableInteractiveSelection: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildNumpad(),
                const SizedBox(height: 16),
                if (_hasBiometric && (_lockType == 'biometric' || _lockType == 'both'))
                  TextButton.icon(
                    onPressed: _attemptBiometric,
                    icon: const Icon(Icons.fingerprint, color: Colors.blue),
                    label: Text(
                      getText('use_fingerprint'),
                      style: const TextStyle(color: Colors.blue),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: _isLockedOut ? null : _showForgotPinDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: Text(getText('forgot_pin')),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}