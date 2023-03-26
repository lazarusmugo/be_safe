import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

class MapsView extends StatefulWidget {
  MapsView({required Key key}) : super(key: key);

  @override
  _MapsViewState createState() => _MapsViewState();
}

class _MapsViewState extends State<MapsView> {
  late GoogleMapController mapController;
  late Marker currentLocationMarker = const Marker(
    markerId: MarkerId("currentLocation"),
    position: LatLng(0, 0),
    infoWindow: InfoWindow(title: " This is your Current Location"),
  );
  late Set<Marker> groupMarkers = {};

  List<Marker> markers = [];

  Future<void> _addGroupMarkers() async {
    // retrieve the groups that the current user is a member of
    List<String> userGroups =
        []; // replace with actual code to get user's groups
    DateTime currentTime = DateTime.now();

    // loop through each group and retrieve the group members with isVisibility = true
    final groupsRef = FirebaseFirestore.instance.collection('groups');
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final visibleGroupsQuerySnapshot =
        await groupsRef.where('memberIds', arrayContains: currentUserId).get();

    final visibleGroupsDocs = visibleGroupsQuerySnapshot.docs;

    final visibleGroupMembers = <Map<String, dynamic>>[];

    for (final doc in visibleGroupsDocs) {
      final groupMembersSnapshot =
          await groupsRef.doc(doc.id).collection('group_members').get();
      final groupMembersDocs = groupMembersSnapshot.docs;
      for (final doc in groupMembersDocs) {
        final memberData = doc.data() as Map<String, dynamic>;

        final visibleUntil = memberData['visibleUntil'];
        if (visibleUntil != null) {
          final visibleUntilTimestamp = visibleUntil as Timestamp;
        }
        final isVisible = memberData['isVisible'] as bool;
        final userId = memberData['userId'] as String;
        final profilePhotoUrl = memberData['profilePhotoUrl'] as String;
        final username = memberData['username'] as String;

        if (isVisible &&
            visibleUntil.toDate().isAfter(DateTime.now()) != null &&
            userId != currentUserId) {
          final member = <String, dynamic>{
            'userId': userId,
            'profilePhotoUrl': profilePhotoUrl,
            'username': username,
            'location': memberData['location'],
          };
          visibleGroupMembers.add(member);
        }
      }
    }

    for (final member in visibleGroupMembers) {
      final location = member['location'] as GeoPoint;
      final latLng = LatLng(location.latitude, location.longitude);
      final username1 = member['username'];
      final profilephoto = member['profilePhotoUrl'];
      final marker = Marker(
        markerId: MarkerId(member['userId']),
        position: latLng,
        infoWindow: InfoWindow(
          title: member['username'],
          snippet: 'Member of your group',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16.0),
                  CircleAvatar(
                    radius: 40.0,
                    backgroundImage: NetworkImage(profilephoto),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    username1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 16.0),
                ],
              );
            },
          );
        },
      );

      markers.add(marker);
    }

    setState(() {
      groupMarkers = Set.of(markers);
      print('list of groupmarkers is $groupMarkers');
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _addGroupMarkers();
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location services disabled"),
            content: const Text(
                "Please enable location services to use this feature."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location permissions denied"),
            content: const Text(
                "Please grant location permissions to use this feature."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        currentLocationMarker = Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentLocation,
          infoWindow: const InfoWindow(title: "Current Location"),
        );
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation,
              zoom: 11.0,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            markers: {
              ...groupMarkers,
              if (currentLocationMarker != null) currentLocationMarker,
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 11.0,
            ),
          ),
        ),
      ),
    );
  }
}
