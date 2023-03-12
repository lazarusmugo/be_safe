import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:async/async.dart';

class GroupMapScreen extends StatefulWidget {
  final String groupId;
  const GroupMapScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupMapScreen> createState() => _GroupMapScreenState();
}

class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);

  @override
  String toString() {
    return 'Location{latitude: $latitude, longitude: $longitude}';
  }
}

class _GroupMapScreenState extends State<GroupMapScreen> {
  Timestamp? _visibleUntil = null;

  int _shareDuration = 1;
  DateTime _customShareDuration = DateTime.now();
  bool _isLocationOn = false;
  bool _alwaysShareLocation = false;
  FirebaseAuth auth = FirebaseAuth.instance;

  Set<Marker> markers = {};
  var _debouncer = CancelableOperation<void>.fromFuture(Future.value());

  // Set a default sharing time
  int _sharingTime = 1;

  // Set a default visibility status
  bool _isVisible = true;

  // Update the sharing time when the user changes it
  void _updateSharingTime(int newTime) {
    setState(() {
      _sharingTime = newTime;
    });
  }

  // Update the visibility status when the user changes it
  void _updateVisibility(bool isVisible) {
    setState(() {
      _isVisible = isVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    // You can add any initial configuration for the map controller here
  }
  @override
  void initState() {
    super.initState();
    String currentUserId = auth.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('group_members')
        .doc(currentUserId)
        .get()
        .then((documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          _visibleUntil = documentSnapshot.get('visibleUntil');
        });
      }
    });
  }

  Stream<DocumentSnapshot> _getUserDataStream() {
    String currentUserId = auth.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('group_members')
        .doc(currentUserId)
        .snapshots();
  }

  void updateMarkers(List<DocumentSnapshot> groupMembers) {
    // Clear the current markers
    markers.clear();

    for (var member in groupMembers) {
      final userData = member.data() as Map<String, dynamic>?;
      if (userData != null) {
        final GeoPoint location = userData['location'];
        final double latitude = location.latitude;
        final double longitude = location.longitude;
        final LatLng latLng = LatLng(latitude, longitude);

        final String name = userData['name'] ?? 'Unknown';
        final String profilePhotoUrl = userData['profile_photo_url'] ?? '';
        final Timestamp visibleUntil = userData['visibleUntil'] != null
            ? userData['visibleUntil']
            : Timestamp.now();

        final bool isVisible = visibleUntil == null ||
            visibleUntil.toDate().isAfter(DateTime.now());
        if (isVisible) {
          markers.add(
            Marker(
              markerId: MarkerId(member.id),
              position: latLng,
              infoWindow: InfoWindow(
                title: name,
                snippet: 'Location visible until: ${visibleUntil.toDate()}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16.0),
                        CircleAvatar(
                          radius: 40.0,
                          backgroundImage: NetworkImage(profilePhotoUrl),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    );
                  },
                );
              },
            ),
          );
        }
      }
    }

    // Use the debouncer to delay the setState call
    _debouncer.cancel();
    _debouncer = CancelableOperation.fromFuture(
        Future.delayed(const Duration(milliseconds: 5000), () {
      setState(() {
        markers = markers;
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Map'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //snaphsot to update map markers
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('group_members')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Clear the current markers
                        markers.clear();

                        final groupMembers = snapshot.data!.docs;

                        // Call setState to update the markers on the map
                        WidgetsBinding.instance!.addPostFrameCallback((_) {
                          updateMarkers(groupMembers);
                        });

                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(width: 20.0),
                    //snapshot for the visibleuntill
                    StreamBuilder<DocumentSnapshot>(
                      stream: _getUserDataStream(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        /*  if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 80, child: Text('Loading...'));
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(
                              height: 80, child: Text('Something went wrong'));
                        }*/
                        final document = snapshot.data!;
                        final visibleUntil = document.get('visibleUntil');
                        _visibleUntil = visibleUntil;

                        return SizedBox(
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.all(13.0),
                            child: Text(
                              'VISIBLE UNTIL: ${_visibleUntil?.toDate().toString() ?? "NOT SHARING"}',
                              style: const TextStyle(
                                fontSize: 19.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20.0),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SHARING OPTIONS',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          const Text(
                            'Always share my location',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _alwaysShareLocation,
                            onChanged: (value) {
                              setState(() {
                                _alwaysShareLocation = value;
                                if (_alwaysShareLocation == true) {
                                  String currentUserId = auth.currentUser!.uid;
                                  DateTime visibleUntil = DateTime.now().add(
                                      const Duration(
                                          days: 7300)); // visible for 20 years
                                  Timestamp timestamp =
                                      Timestamp.fromDate(visibleUntil);
                                  FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(widget.groupId)
                                      .collection('group_members')
                                      .doc(currentUserId)
                                      .update({
                                    'visibleUntil': timestamp,
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10.0),
                          const Text(
                            'Or select a custom duration:',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                  child: ElevatedButton(
                                onPressed: () {
                                  showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  ).then((selectedTime) {
                                    if (selectedTime != null) {
                                      final now = DateTime.now();
                                      final duration = Duration(
                                        hours: selectedTime.hour - now.hour,
                                        minutes:
                                            selectedTime.minute - now.minute,
                                      );
                                      setState(() {
                                        _customShareDuration =
                                            now.add(duration);
                                      });
                                      String currentUserId =
                                          auth.currentUser!.uid;
                                      FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(widget.groupId)
                                          .collection('group_members')
                                          .doc(currentUserId)
                                          .update({
                                        'visibleUntil': Timestamp.fromDate(
                                            _customShareDuration)
                                      });
                                    }
                                  });
                                },
                                child: const Text('Select Time'),
                              )),
                              const SizedBox(width: 10.0),
                              Text(
                                _customShareDuration != null
                                    ? 'Selected duration: ${_customShareDuration.difference(DateTime.now()).inHours} hours ${_customShareDuration.difference(DateTime.now()).inMinutes % 60} minutes'
                                    : 'No duration selected',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        markers: markers,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(0, 0),
                          zoom: 0.0,
                        ),
                        zoomControlsEnabled: true, // Enables zoom controls
                        scrollGesturesEnabled: true, // Enables scroll gestures
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
