import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  // ডিফল্ট টাইপ 'Expense' (খরচ)
  String _selectedType = 'Expense';
  DateTime _selectedDate = DateTime.now();
  DateTime? _reminderDateTime;

  // নোটের জন্য ডিফল্ট কালার (Teal)
  int _selectedColor = 0xFF009688;

  // কালার লিস্ট
  final List<int> _noteColors = [
    0xFF009688, // Teal
    0xFFFF8A80, // Light Red
    0xFF80D8FF, // Light Blue
    0xFFFFFF8D, // Yellow
    0xFFCCFF90, // Light Green
    0xFFCFD8DC, // Blue Grey
  ];

  // তারিখ এবং সময় সিলেক্ট করার ফাংশন
  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _reminderDateTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute,
          );
          // ট্রানজেকশনের জন্য মূল ডেট আপডেট
          _selectedDate = date;
        });
      }
    }
  }

  void _saveEntry() async {
    // ভ্যালিডেশন
    if (_selectedType != 'Note' && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("টাকার পরিমাণ লিখুন")),
      );
      return;
    }

    if (_selectedType == 'Note' && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("নোটের টাইটেল লিখুন")),
      );
      return;
    }

    try {
      // ১. ট্রানজেকশন (জমা / খরচ / দেনা) সেভ করা
      if (_selectedType != 'Note') {
        final tx = TransactionModel(
          amount: double.tryParse(_amountController.text) ?? 0,
          type: _selectedType, // এখানে 'Income', 'Expense' বা 'Debt' (দেনা) সেভ হবে
          category: "General",
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          note: _noteController.text.isEmpty ? _selectedType : _noteController.text,
          refundDate: _reminderDateTime?.toString(),
          isPaid: false,
        );
        await DatabaseService().addTransaction(tx);
      }

      // ২. শুধুমাত্র নোট সেভ করা
      else {
        await DatabaseService().saveNote(
          title: _titleController.text,
          content: _noteController.text,
          reminderDateTime: _reminderDateTime?.toString(),
          colorValue: _selectedColor,
        );
      }

      // ৩. রিমাইন্ডার/অ্যালার্ম সেট করা (যদি সময় সিলেক্ট করা থাকে)
      if (_reminderDateTime != null) {
        String notificationTitle = "";
        if (_selectedType == 'Debt' || _selectedType == 'দেনা') {
          notificationTitle = "টাকা ফেরতের রিমাইন্ডার";
        } else if (_selectedType == 'Note') {
          notificationTitle = "নোট রিমাইন্ডার: ${_titleController.text}";
        } else {
          notificationTitle = "লেনদেন রিমাইন্ডার";
        }

        NotificationService.scheduleReminder(
          DateTime.now().millisecondsSinceEpoch ~/ 1000, // ইউনিক আইডি
          notificationTitle,
          _noteController.text.isEmpty ? "আপনার একটি রিমাইন্ডার আছে" : _noteController.text,
          _reminderDateTime!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("সফলভাবে সেভ হয়েছে")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("নতুন $_selectedType এন্ট্রি"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // টাইপ সিলেক্টর
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Income', label: Text('জমা')),
                  ButtonSegment(value: 'Expense', label: Text('খরচ')),
                  ButtonSegment(value: 'Debt', label: Text('দেনা')), // এটি 'HomeScreen' এর ব্যালেন্স প্লাস করবে
                  ButtonSegment(value: 'Note', label: Text('নোট')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.teal,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // টাকার ইনপুট (নোট ছাড়া সবার জন্য)
            if (_selectedType != 'Note')
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "টাকার পরিমাণ",
                  prefixText: "৳ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

            // টাইটেল ইনপুট (শুধুমাত্র নোটের জন্য)
            if (_selectedType == 'Note')
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "নোট বা মিটিংয়ের শিরোনাম",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

            const SizedBox(height: 20),

            // কালার সিলেক্টর (শুধুমাত্র নোটের জন্য)
            if (_selectedType == 'Note') ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("নোটের কালার পছন্দ করুন:", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _noteColors.length,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = _noteColors[index]),
                    child: Container(
                      width: 45,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Color(_noteColors[index]),
                        shape: BoxShape.circle,
                        border: _selectedColor == _noteColors[index]
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // তারিখ ও সময় বাটন
            ListTile(
              tileColor: Colors.teal.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.calendar_today, color: Colors.teal),
              trailing: const Icon(Icons.access_time, color: Colors.teal),
              title: Text(
                _reminderDateTime == null
                    ? "তারিখ ও সময় সেট করুন"
                    : DateFormat('dd MMMM, yyyy - hh:mm a').format(_reminderDateTime!),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: _pickDateTime,
            ),

            const SizedBox(height: 20),

            // বিস্তারিত নোট
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _selectedType == 'Note' ? "নোটের বিস্তারিত..." : "লেনদেনের বিবরণ...",
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 35),

            // সেভ বাটন
            ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save),
              label: const Text("সব তথ্য সেভ করুন", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}