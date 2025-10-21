// lib/widgetek/kozos_widgetek.dart
import 'package:flutter/material.dart';

// Ez a beviteli kártya a Jármű hozzáadása/szerkesztése képernyőhöz.
class KozosBemenetiKartya extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child; // Ez fogadja be a TextFormField-et, Dropdown-t, stb.
  final EdgeInsets? padding;

  const KozosBemenetiKartya({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // A GestureDetector biztosítja, hogy a kártya teljes felülete kattintható.
    return GestureDetector(
      onTap: () {
        // Amikor a kártyára kattintunk, a benne lévő beviteli mező kapja meg a fókuszt.
        FocusScope.of(context).requestFocus(Focus.of(context).children.first);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: padding ??
              const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    // Itt jelenik meg a TextFormField vagy a DropdownSearch
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
