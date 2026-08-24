import 'package:flutter/material.dart';
import 'package:open_tag_app/theme/app_theme.dart';

class TopFloatingBar extends StatefulWidget {
  final VoidCallback onThemeToggle;

   const TopFloatingBar({
     super.key, 
     required this.onThemeToggle,
   });

   @override
   State<TopFloatingBar> createState() => _TopFloatingBarState();
}

class _TopFloatingBarState extends State<TopFloatingBar> {

   @override
   Widget build(BuildContext context) {
     return Container(
       height: 50,
       decoration: BoxDecoration(
         color: Theme.of(context).brightness == Brightness.dark
             ? const Color.fromARGB(255, 55, 55, 55)
             : const Color(0xFFBDBDBD),
         boxShadow: const [
           BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
         ],
       ),
       child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                : const SizedBox(width: 48),
            Text(
              'Open Tag',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            IconButton(
              tooltip: Theme.of(context).brightness == Brightness.dark ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: widget.onThemeToggle,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
              ),
            ),
          ],
        )
     );
   }
}