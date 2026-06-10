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
    final reason = widget.language == 'bn'
        ? 'অ্যাপ আনলক করতে ফিঙ্গারপ্রিন্ট দিন'
        : 'Authenticate to open app';
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
      widget.onUnlocked(true);
    } else {
      setState(() {
        _attempts++;
        _pin = '';
        _pinController.clear();
        if (_attempts >= 5) {
          _isLockedOut = true;
          _errorMessage = widget.language == 'bn'
              ? 'অনেকবার ভুল হয়েছে। ৩০ সেকেন্ড অপেক্ষা করুন'
              : 'Too many attempts. Wait 30 seconds';
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
          _errorMessage = widget.language == 'bn'
              ? 'ভুল পিন! আবার চেষ্টা করুন (${5 - _attempts} বার বাকি)'
              : 'Wrong PIN! Try again (${5 - _attempts} attempts left)';
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

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _buildNumpadButton('1'),
          _buildNumpadButton('2'),
          _buildNumpadButton('3'),
          _buildNumpadButton('4'),
          _buildNumpadButton('5'),
          _buildNumpadButton('6'),
          _buildNumpadButton('7'),
          _buildNumpadButton('8'),
          _buildNumpadButton('9'),
          _buildFingerprintButton(),
          _buildNumpadButton('0'),
          _buildDeleteButton(),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLockedOut ? null : () => _onPinEntered(_pin + number),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLockedOut ? null : () {
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
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Icon(Icons.backspace_outlined, size: 28, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintButton() {
    if (!_hasBiometric) return const SizedBox();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLockedOut ? null : _attemptBiometric,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Icon(Icons.fingerprint, size: 36, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet, size: 60, color: Colors.blue),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.language == 'bn' ? 'আমার হিসাব' : 'My Accounting',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.language == 'bn' ? 'অ্যাপ খুলতে পিন লিখুন' : 'Enter PIN to unlock',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pin.length > index ? Colors.blue : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(_errorMessage, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14)),
                  ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Opacity(
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
                ),
                const SizedBox(height: 30),
                _buildNumpad(),
                const SizedBox(height: 30),
                if (_hasBiometric && (_lockType == 'biometric' || _lockType == 'both'))
                  TextButton.icon(
                    onPressed: _attemptBiometric,
                    icon: const Icon(Icons.fingerprint, color: Colors.blue),
                    label: Text(
                      widget.language == 'bn' ? 'ফিঙ্গারপ্রিন্ট ব্যবহার করুন' : 'Use Fingerprint',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}