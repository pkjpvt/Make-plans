import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_typeahead/flutter_typeahead.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  int passengers = 1;
  String travelClass = 'Economy';
  bool isLoading = false;
  String error = '';
  List flights = [];

  final List<String> airports = [
    'Delhi (DEL)',
    'Mumbai (BOM)',
    'Bangalore (BLR)',
    'Chennai (MAA)',
    'Hyderabad (HYD)',
    'Kolkata (CCU)',
    'Pune (PNQ)',
    'Ahmedabad (AMD)',
    'Goa (GOI)',
    'Dubai (DXB)',
  ];

  /// 🔧 Extracts city name from full label like "Delhi (DEL)" → "Delhi"
  String _getCityName(String input) {
    return input.split(' (').first.trim();
  }

  Future<List<String>> getSuggestions(String query) async {
    return airports
        .where((airport) => airport.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> fetchFlights() async {
    final source = _sourceController.text.trim();
    final destination = _destinationController.text.trim();

    if (source.isEmpty || destination.isEmpty) {
      setState(() => error = 'Please enter both source and destination.');
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
      flights = [];
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // ✅ Extract only city names for API
    final sourceCity = _getCityName(source);
    final destinationCity = _getCityName(destination);

    final uri = Uri.parse(
      'https://cb46-2401-4900-5028-cb63-8a-6e6c-b706-bfca.ngrok-free.app/makeplans-api/api/flights/search_flights.php'
          '?source=${Uri.encodeComponent(sourceCity)}'
          '&destination=${Uri.encodeComponent(destinationCity)}'
          '&date=$formattedDate&class=$travelClass&passengers=$passengers',
    );

    try {
      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (data['status'] == true) {
        setState(() {
          flights = data['flights'];
        });
      } else {
        setState(() {
          error = data['message'] ?? 'No flights available';
        });
      }
    } catch (e) {
      setState(() {
        error = '❌ Error fetching flights';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Flight Search'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTypeAheadField('From', _sourceController),
            const SizedBox(height: 12),

            _buildTypeAheadField('To', _destinationController),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _pickDate(context),
                  child: Text(
                    'Departure: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: passengers,
                    decoration: const InputDecoration(labelText: 'Travellers'),
                    items: List.generate(6, (index) => index + 1)
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => passengers = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: travelClass,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: const [
                      DropdownMenuItem(value: 'Economy', child: Text('Economy')),
                      DropdownMenuItem(value: 'Premium Economy', child: Text('Premium Economy')),
                      DropdownMenuItem(value: 'Business', child: Text('Business')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => travelClass = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: fetchFlights,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SEARCH FLIGHTS', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.redAccent))
            else if (flights.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: flights.length,
                  itemBuilder: (context, index) {
                    final flight = flights[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Image.network(
                          flight['logo'],
                          height: 40,
                          width: 40,
                          errorBuilder: (_, __, ___) => const Icon(Icons.flight),
                        ),
                        title: Text('${flight['airline']} (${flight['flight_no']})'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${flight['source_code']} → ${flight['destination_code']}'),
                            Text('${flight['departure'].substring(11, 16)} - ${flight['arrival'].substring(11, 16)} • ${flight['duration']}'),
                            Text('Class: ${flight['class']} | Pax: ${flight['passengers']}'),
                          ],
                        ),
                        trailing: Text(
                          '₹${flight['price']}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeAheadField(String label, TextEditingController controller) {
    return TypeAheadFormField<String>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.flight_takeoff),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      suggestionsCallback: getSuggestions,
      itemBuilder: (context, String suggestion) {
        return ListTile(title: Text(suggestion));
      },
      onSuggestionSelected: (String suggestion) {
        controller.text = suggestion;
      },
    );
  }
}
