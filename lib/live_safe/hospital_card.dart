import 'package:flutter/material.dart';

class Hospital extends StatelessWidget {
  final Function? onMapFunction;
  const Hospital({super.key, this.onMapFunction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              onMapFunction!('Hospitals near me');
            },
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                height: 65,
                width: 65,
                child: Center(
                  child: Image.asset(
                    "assets/ambulance.png",
                    height: 40,
                  ),
                ),
              ),
            ),
          ),
          const Text("Hospitals")
        ],
      ),
    );
  }
}
