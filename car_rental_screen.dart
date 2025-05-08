import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _cars = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableCars(""); // Fetch all cars initially (empty location)
  }

  Future<void> _fetchAvailableCars(String location) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cars = [];
    });

    try {
      final response = await http.get(
        Uri.parse(
          "https://cb46-2401-4900-5028-cb63-8a-6e6c-b706-bfca.ngrok-free.app/makeplans-api/api/cabs/available_rental.php?location=$location",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == true) {
          setState(() {
            _cars = data["cars"];
          });
        } else {
          setState(() {
            _errorMessage = data["message"] ?? "No cars found.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    String carName = "${car["make"] ?? ""} ${car["model"] ?? ""}";
    int? price = car["price"];
    int? seats = car["seats"];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "https://picsum.photos/100/80", // Placeholder image
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.directions_car, size: 60),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Seats: ${seats ?? '-'}",
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${price ?? '-'} /day",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Car Rentals"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Enter Location",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final loc = _locationController.text.trim();
                _fetchAvailableCars(loc); // Fetch cars based on the input location
              },
              child: const Text("Search Cars"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
                  : _cars.isEmpty
                  ? const Center(child: Text("No cars available"))
                  : ListView.builder(
                itemCount: _cars.length,
                itemBuilder: (context, index) {
                  return _buildCarCard(_cars[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
