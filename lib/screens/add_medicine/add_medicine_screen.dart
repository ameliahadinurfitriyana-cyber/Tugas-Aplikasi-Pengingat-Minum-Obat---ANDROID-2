import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/medicine.dart';
import '../../models/reminder.dart';
import '../../providers/medicine_provider.dart';
import '../../services/database_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _stockController;
  late TextEditingController _notesController;

  String _selectedType = 'Tablet';
  String _selectedColor = '#3B82F6';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  String _selectedRepeatType = 'Every Day';
  List<String> _selectedCustomDays = [];

  List<String> _remindersTimes = ['08:00'];

  final List<String> _medicineTypes = [
    'Tablet',
    'Kapsul',
    'Sirup',
    'Tetes',
    'Suntik',
  ];
  final List<String> _presetColors = [
    '#3B82F6', // Blue
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#6366F1', // Indigo
    '#14B8A6', // Teal
  ];

  final Map<String, String> _repeatOptions = {
    'Every Day': 'Setiap Hari',
    'Mon-Fri': 'Senin-Jumat',
    'Custom': 'Kustom Hari',
  };

  final List<String> _daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  bool _isLoadingReminders = false;

  @override
  void initState() {
    super.initState();

    final isEditing = widget.medicine != null;

    _nameController = TextEditingController(
      text: isEditing ? widget.medicine!.name : '',
    );
    _dosageController = TextEditingController(
      text: isEditing ? widget.medicine!.dosage : '',
    );
    _stockController = TextEditingController(
      text: isEditing ? widget.medicine!.stock.toString() : '10',
    );
    _notesController = TextEditingController(
      text: isEditing ? widget.medicine!.notes : '',
    );

    if (isEditing) {
      _selectedType = widget.medicine!.type;
      _selectedColor = widget.medicine!.color;
      _startDate = widget.medicine!.startDate;
      _endDate = widget.medicine!.endDate;
      _loadRemindersForEditing();
    }
  }

  Future<void> _loadRemindersForEditing() async {
    setState(() {
      _isLoadingReminders = true;
    });

    try {
      final dbReminders = await DatabaseService.instance
          .getRemindersForMedicine(widget.medicine!.id!);
      if (dbReminders.isNotEmpty) {
        setState(() {
          _remindersTimes = dbReminders.map((r) => r.time).toList();
          _selectedRepeatType = dbReminders.first.repeatType;
          _selectedCustomDays = List<String>.from(dbReminders.first.days);
        });
      }
    } catch (e) {
      debugPrint("Error loading reminders: $e");
    } finally {
      setState(() {
        _isLoadingReminders = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (!mounted) return;

    if (picked != null) {
      final String timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (!_remindersTimes.contains(timeStr)) {
        setState(() {
          _remindersTimes.add(timeStr);
          _remindersTimes.sort();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jam pengingat sudah ada.')),
        );
      }
    }
  }

  void _removeTime(int index) {
    if (_remindersTimes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 pengingat.')),
      );
      return;
    }
    setState(() {
      _remindersTimes.removeAt(index);
    });
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_remindersTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap tambahkan minimal satu jam pengingat.'),
        ),
      );
      return;
    }

    if (_selectedRepeatType == 'Custom' && _selectedCustomDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu hari untuk pengingat kustom.'),
        ),
      );
      return;
    }

    final provider = Provider.of<MedicineProvider>(context, listen: false);

    final medicine = Medicine(
      id: widget.medicine?.id,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      type: _selectedType,
      color: _selectedColor,
      notes: _notesController.text.trim(),
      stock: int.tryParse(_stockController.text) ?? 0,
      startDate: _startDate,
      endDate: _endDate,
      createdAt: widget.medicine?.createdAt ?? DateTime.now(),
    );

    final List<Reminder> reminders = _remindersTimes.map((time) {
      return Reminder(
        time: time,
        repeatType: _selectedRepeatType,
        days: _selectedRepeatType == 'Custom' ? _selectedCustomDays : [],
        isActive: true,
      );
    }).toList();

    try {
      if (widget.medicine != null) {
        await provider.updateMedicine(medicine, reminders);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat berhasil diperbarui.')),
          );
        }
      } else {
        await provider.addMedicine(medicine, reminders);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obat berhasil ditambahkan.')),
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving medicine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Gagal menyimpan obat. $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.medicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Obat' : 'Tambah Obat Baru'),
        actions: [
          IconButton(
            onPressed: _saveMedicine,
            icon: const Icon(Icons.check_rounded, size: 28),
          ),
        ],
      ),
      body: _isLoadingReminders
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  // Form Fields
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Obat',
                      prefixIcon: const Icon(Icons.medication_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama obat wajib diisi';
                      }
                      if (value.trim().length < 2) {
                        return 'Nama obat minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Dosage
                      Expanded(
                        child: TextFormField(
                          controller: _dosageController,
                          decoration: InputDecoration(
                            labelText: 'Dosis (e.g. 500 mg)',
                            prefixIcon: const Icon(Icons.scale_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Dosis wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stock
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Stok',
                            prefixIcon: const Icon(Icons.inventory_2_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Wajib diisi';
                            }
                            final intVal = int.tryParse(value);
                            if (intVal == null || intVal < 0) {
                              return 'Stok minimal 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Type
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Jenis Obat',
                      prefixIcon: const Icon(Icons.category_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: _medicineTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Preset Colors Grid Selector
                  Text('Pilih Warna Obat', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetColors.length,
                      separatorBuilder: (context, idx) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final colorStr = _presetColors[idx];
                        final color = Color(
                          int.parse(colorStr.replaceFirst('#', '0xff')),
                        );
                        final isSelected = _selectedColor == colorStr;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColor = colorStr),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Picker Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, true),
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: Text(
                            'Mulai: ${DateFormat('dd/MM/yyyy').format(_startDate)}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, false),
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: Text(
                            'Selesai: ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Repeat Interval Selector
                  Text(
                    'Frekuensi Pengingat',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _repeatOptions.keys.map((option) {
                      final label = _repeatOptions[option]!;
                      final isSelected = _selectedRepeatType == option;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: theme.primaryColor,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.primaryColor
                                    : Colors.grey[400]!,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedRepeatType = option;
                                });
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Custom Day Picker (only visible if Custom repeat selected)
                  if (_selectedRepeatType == 'Custom') ...[
                    const SizedBox(height: 8),
                    Text('Pilih Hari:', style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _daysOfWeek.map((day) {
                        final isSelected = _selectedCustomDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCustomDays.add(day);
                              } else {
                                _selectedCustomDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Time Reminders List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Waktu Pengingat',
                        style: theme.textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _addTime,
                        icon: const Icon(Icons.more_time_rounded),
                        label: const Text('Tambah Jam'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: _remindersTimes.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text('Belum ada jam pengingat.'),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _remindersTimes.length,
                            separatorBuilder: (context, idx) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final time = _remindersTimes[idx];
                              return ListTile(
                                leading: const Icon(Icons.access_time_rounded),
                                title: Text(
                                  time,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () => _removeTime(idx),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Notes Fields
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Catatan Khusus (Opsional)',
                      prefixIcon: const Icon(Icons.note_alt_rounded),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Perbarui Informasi Obat' : 'Simpan Obat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
