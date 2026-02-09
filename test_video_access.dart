import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const baseUrl = 'http://192.168.1.2:5000/api';
  const token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjRiMTFjYjdhYjVmY2JlNDFlOTQ4MDk0ZTlkZjRjNWI1ZWNhMDAwOWUiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoidHV5aXplcmUgZGlldWRvbm5lIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2V4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1ZCI6ImV4Y2VsbGVuY2Vjb2FjaGluZ2h1Yi01NTk3YyIsImF1dGhfdGltZSI6MTc3MDQ2NjU3MSwidXNlcl9pZCI6IlBCdXFoQUZCeUlkakJtUm1iN2M4SFBXc1BhbjEiLCJzdWIiOiJQQnVxaEFGQnlJZGpCbVJtYjdjOEhQV3NQYW4xIiwiaWF0IjoxNzcwNDY2NTcxLCJleHAiOjE3NzA0NzAxNzEsImVtYWlsIjoiZGlldWRvbm5ldHV5MjUwQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7Imdvb2dsZS5jb20iOlsiMTAwNDUzNTExMDExMjE0MzY1ODQ1Il0sImVtYWlsIjpbImRpZXVkb25uZXR1eTI1MEBnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.Fs5O6FUKYzEbjUfBGSnI4fvSuJTeoLfNmvdUa61Q4C4mi0k_mAnT17gAXChCBz_sD3ApopNZSoQFHFi-UQeROtrc52BnAy85lK5-D3-f5TnyQ62QpsbrF2uIeh52E_gGBPlApwpyRiz85VVFpqWnWSgb04xoMnv4P94SXhRKvFsH4foJ4Wmgl0jyzROyyk3aElgmmSj96_1SMJMLZ1nv9_t9e9v_v02X-1sbyXklwJts9kL-trk7BtmgKMab4c-SBjjNPn8kz93AL5T1uyPxp-ZrslszsrTey0_tH2MCbr4CD5raQ2A5SdMQRgNpWnpvEhZhGQXdaAO2NKBJglPSZw';
  
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  print('Testing Video Access...\n');

  // Test 1: Get lesson details
  print('1. Getting lesson details:');
  try {
    final lessonResponse = await http.get(
      Uri.parse('$baseUrl/lessons/69859816d96a24ae4e945d15'),
      headers: headers,
    );
    
    print('Status: ${lessonResponse.statusCode}');
    if (lessonResponse.statusCode == 200) {
      final lessonData = json.decode(lessonResponse.body);
      final videoId = lessonData['data']['videoId'];
      print('Video ID: $videoId\n');
      
      // Test 2: Get streaming URL
      print('2. Getting streaming URL:');
      final streamResponse = await http.get(
        Uri.parse('$baseUrl/videos/69859816d96a24ae4e945d15/stream-url'),
        headers: headers,
      );
      
      print('Status: ${streamResponse.statusCode}');
      if (streamResponse.statusCode == 200) {
        final streamData = json.decode(streamResponse.body);
        final streamingUrl = streamData['data']['streamingUrl'];
        print('Streaming URL: $streamingUrl\n');
        
        // Test 3: Try to access the streaming URL directly
        print('3. Testing direct access to streaming URL:');
        try {
          final directResponse = await http.head(Uri.parse(streamingUrl));
          print('Direct access status: ${directResponse.statusCode}');
          
          if (directResponse.statusCode == 200) {
            print('✅ Video is accessible!');
          } else if (directResponse.statusCode == 403) {
            print('❌ Video access forbidden (403)');
            print('This usually means:');
            print('- The file doesn\'t exist in S3');
            print('- S3 bucket permissions are incorrect');
            print('- The signed URL has expired');
          } else {
            print('❓ Unexpected status code: ${directResponse.statusCode}');
          }
        } catch (e) {
          print('❌ Error accessing streaming URL: $e');
        }
      } else {
        print('Error getting streaming URL: ${streamResponse.body}');
      }
    } else {
      print('Error getting lesson: ${lessonResponse.body}');
    }
  } catch (e) {
    print('Network error: $e');
  }
}