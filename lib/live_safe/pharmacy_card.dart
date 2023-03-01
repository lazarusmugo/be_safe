import 'package:flutter/material.dart';

class PharmacyCard extends StatelessWidget {
  final Function? onMapFunction;
  const PharmacyCard({super.key, this.onMapFunction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              onMapFunction!('Pharmacies near me');
            },
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                height: 65,
                width: 65,
                child: Center(
                  child: Image.asset(
                    "assets/pharmacy.png",
                    height: 40,
                  ),
                ),
              ),
            ),
          ),
          const Text("Pharmacies")
        ],
      ),
    );
  }
}
