import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert; 
import 'package:intl/intl.dart';

void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final TextEditingController _inputController = TextEditingController();

  bool isDeviceLoc = false;

  final _apiKey = "YOUR_API_KEY";
  var _latitude="";
  var _longitude="";
  var map = {};

  showSnack(String text,bool popDialog){
    if (popDialog) Navigator.of(context).pop();
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _getWeatherData() async {
    var url = "https://api.openweathermap.org/data/2.5/weather?lat=$_latitude&lon=$_longitude&appid=$_apiKey";
    var response = await http.get(Uri.parse(url));
    if(response.statusCode==200){
      var jsonResponse = convert.jsonDecode(response.body);
      try{
        setState(() {
          //print(jsonResponse);
          map['_main'] = jsonResponse['weather'][0]['main'];
          map['_description'] = jsonResponse['weather'][0]['description'];
          map['_imageIcon'] = jsonResponse['weather'][0]['icon'];
          map['_locationName'] = jsonResponse['name'];
          if (map['_locationName'].toLowerCase()!=_inputController.text.toLowerCase() && !isDeviceLoc) {
            map['_locationName'] = "${_inputController.text} (${map['_locationName']})";
          }
          map['_locationCountry'] = jsonResponse['sys']['country'];
          map['_temp'] = (jsonResponse['main']['temp']-273.15).toStringAsFixed(2);
          map['_tempMin'] = (jsonResponse['main']['temp_min']-273.15).toStringAsFixed(2);
          map['_tempMax'] = (jsonResponse['main']['temp_max']-273.15).toStringAsFixed(2);
          map['_humidity'] = jsonResponse['main']['humidity'].toString();
          map['_windSpeed'] = jsonResponse['wind']['speed'].toString();
          map['_sunRise'] = DateFormat('HH:mm aa').format(DateTime.fromMillisecondsSinceEpoch(jsonResponse['sys']['sunrise']*1000)).toString();
          map['_sunSet'] = DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(jsonResponse['sys']['sunset']*1000)).toString();
        });
      }catch(e){
        showSnack("Line 64 : $e",true);
      }
    }else{
      showSnack("Line : 54 ${response.statusCode}",true);
    }
  }

  Future<bool> _handleLocationPermission() async{
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      showSnack("Location sevice disabled. Enable them",true);
      return false;
    }
    permission = await Geolocator.checkPermission();
    if(permission==LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if (permission==LocationPermission.denied) {
        showSnack("You denied the permission",true);
        return false;
      }
    }
    if (permission==LocationPermission.deniedForever) {
      showSnack("You denied the permission forever",true);
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async{
    _showLoadDialog();
    final hasPosition = await _handleLocationPermission();
    if(!hasPosition) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then(
      (value) {
         _latitude = value.latitude.toString();
        _longitude = value.longitude.toString();
        _getWeatherData();
      }
    ).catchError((e){
      showSnack("line 74 : $e",true);
    });
  }

  Future<void> _getPositionFromName() async{
    _showLoadDialog();
    var url = 'http://api.openweathermap.org/geo/1.0/direct?q=${_inputController.text}&limit=5&appid=$_apiKey';
    var response = await http.get(Uri.parse(url));
    if(response.statusCode==200){
      var jsonResponse = convert.jsonDecode(response.body);
        _latitude = jsonResponse[0]['lat'].toString();
        _longitude = jsonResponse[0]['lon'].toString();
        _getWeatherData();
    }else{
      showSnack("response code : ${response.statusCode}",true);
    }
  }

  Widget loadDetails(){
    Navigator.of(context).pop();
      return Center(
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              shape: BoxShape.rectangle,
              color: Colors.white70,
          ),
          width: 450,
          height: 350,
          child: Card(
              child: Column(
                children: [
                  Image.network("https://openweathermap.org/img/wn/${map['_imageIcon']}@2x.png"),
                  Text(map['_main'],style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                  const Padding(padding: EdgeInsets.only(bottom: 5)),
                  Text(map['_description']),
                  const Padding(padding: EdgeInsets.only(bottom: 5)),
                  Text("${map['_locationName']} , ${map['_locationCountry']}",style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                  const Padding(padding: EdgeInsets.only(bottom: 20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Temperature : ",style: TextStyle(fontWeight: FontWeight.bold),),
                      Text("${map['_temp']}°C"),
                    ],
                  ),
                  /*const Padding(padding: EdgeInsets.all(5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Min Temp : "),
                      Text("$_tempMin°C",style: const TextStyle(fontWeight: FontWeight.bold),),
                      const Padding(padding: EdgeInsets.only(right: 15)),
                      const Text("Max Temp : "),
                      Text("$_tempMax°C",style: const TextStyle(fontWeight: FontWeight.bold),),
                    ],
                  ),*/
                  const Padding(padding: EdgeInsets.only(bottom: 10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Humidity : ",style: TextStyle(fontWeight: FontWeight.bold),),
                      Text("${map['_humidity']}%"),
                      const Padding(padding: EdgeInsets.only(right: 15)),
                      const Text("Wind Speed : ",style: TextStyle(fontWeight: FontWeight.bold),),
                      Text("${map['_windSpeed']} m/s")
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(bottom: 10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sunrise : ",style: TextStyle(fontWeight: FontWeight.bold),),
                      Text(map['_sunRise']),
                      const Padding(padding: EdgeInsets.only(right: 15)),
                      const Text("Sunset : ",style: TextStyle(fontWeight: FontWeight.bold),),
                      Text(map['_sunSet'])
                    ],
                  ),
                  const Padding(padding: EdgeInsets.all(20)),
                  TextButton(
                    onPressed: (){
                      setState(() {
                        map.clear();
                        isDeviceLoc = false;
                        _inputController.text="";
                      });
                    }, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back),
                        Text("Go Back",style: TextStyle(color: Colors.lightBlue),)
                      ]
                    )
                  )
                ],
              ),
          ),
        ),
      );
  }

  bool _checkDetails(){
    if(map.isNotEmpty){
      return true;
    }
    return false;
  }

  void _showLoadDialog(){
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white70,
      pageBuilder: (BuildContext buildContext,
          Animation animation,
          Animation secondaryAnimation) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            Padding(padding: EdgeInsets.all(10)),
            Material(
              child: Text("Please wait...",style: TextStyle(fontSize: 20),),
            )
          ],
        );
      }
    );
  }

  Future<bool> _onBackPressed() async {
    if(map.isNotEmpty){
      setState(() {
        map.clear();
        isDeviceLoc = false;
        _inputController.text="";
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/cloud.webp"),
              fit: BoxFit.cover
            )
          ), 
          child: Center(
            child: _checkDetails() ? loadDetails() : Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                shape: BoxShape.rectangle,
                color: Colors.white70,
              ),
              width: 350,
              height: 250,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 20)),
                    Container(
                      width: 300,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        shape: BoxShape.rectangle
                      ),
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Search a Place'
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 10)),
                    SizedBox(
                      width: 250,
                      child: CheckboxListTile(
                      value: isDeviceLoc, 
                      onChanged: (bool? value){
                        setState(() {
                          isDeviceLoc = value!;
                        });
                      },
                      title: const Text("Use Device's Location"),
                      controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
                    ElevatedButton(
                      onPressed: (){
                          if(isDeviceLoc){
                            _getCurrentPosition();
                          }else if(_inputController.text.isNotEmpty){
                            _getPositionFromName();
                          }else{
                            showSnack("Enter city name or check the checkbox",false);
                          }
                      },
                      child: const Text("Get Weather")
                    ),
                    const Padding(padding: EdgeInsets.only(bottom: 20)),
                  ],
                ),
              ),
            ),
          )
        )
      ),
    );
  }
}