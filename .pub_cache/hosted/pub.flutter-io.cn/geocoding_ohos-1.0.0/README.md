# geocoding_ohos

Geocoding Ohos plugin which provides easy geocoding and reverse-geocoding features.
The geocoding ohos plugin implementation of [`geocoding`][1].

## Usage

```yaml
dependencies:
  geocoding: 3.0.0
  geocoding_ohos: 1.0.0
```

This package is [endorsed][2], which means you can simply use `geocoding`
normally. This package will be automatically included in your app when you do,Some core function or 
method are used as follow:  

import 'package:geocoding_ohos/geocoding_ohos.dart';  

instantiate the GeocodingOhos class in your field like this:  

GeocodingOhos _geocodingOhos = GeocodingOhos();  

eg: get place mark from given coordinates  
_geocodingOhos.placemarkFromCoordinates(latitude, longitude).then((placemarks) {  
    var output = 'No results found.';  
    if (placemarks.isNotEmpty) {  
        output = placemarks[0].toString();    
    }  
});  

eg: get place mark from given address  
_geocodingOhos.placemarkFromAddress(_addressController.text).then((locations) {  
    var output = 'No results found.';   
    if (locations.isNotEmpty) {  
        output = locations[0].toString();  
    }  
});  

eg: get locations from given address  
_geocodingOhos.locationFromAddress(_addressController.text).then((locations) {  
    var output = 'No results found.';  
    if (locations.isNotEmpty) {  
        output = locations[0].toString();  
    }  
});  

eg: whether the geocoding service is available  
_geocodingOhos.isPresent().then((isPresent) {  
    var output = isPresent ? "Geocoder is present": "Geocoder is not present";  
}); 
 
eg: set locale identifier en_US nl_NL zh_CN ...  
_geocodingOhos.setLocaleIdentifier("en_US").then((_) {  

});  

