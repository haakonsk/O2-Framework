o2.escape = {};

// According to RFC 3986, only characters from a set of reserved and a set
// of unreserved characters are allowed in a URL:
var unreserved = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_.~";
var reserved   = "!*'();:@&=+$,/?%#[]";
var allowed    = unreserved + reserved;
var hexchars   = "0123456789ABCDEFabcdef";

o2.escape.getEncoding = function() {
  return 'utf-8';
}

// Found on http://www.hypergurl.com/urlencode.html. Thank you!
o2.escape.escape = function(str) {
  if (!str) {
    return "";
  }
  var encoded = "";

  for (var i = 0; i < str.length; i++) {
    var ch = str.charAt(i);
    // Check if character is an unreserved character:
    if (unreserved.indexOf(ch) != -1) {
      encoded = encoded + ch;
    }
    else {

      // The position in the Unicode table tells us how many bytes are needed.
      // Note that if we talk about first, second, etc. in the following, we are
      // counting from left to right:
      //
      //   Position in   |  Bytes needed   | Binary representation
      //  Unicode table  |   for UTF-8     |       of UTF-8
      // ----------------------------------------------------------
      //     0 -     127 |    1 byte       | 0XXX.XXXX
      //   128 -    2047 |    2 bytes      | 110X.XXXX 10XX.XXXX
      //  2048 -   65535 |    3 bytes      | 1110.XXXX 10XX.XXXX 10XX.XXXX
      // 65536 - 2097151 |    4 bytes      | 1111.0XXX 10XX.XXXX 10XX.XXXX 10XX.XXXX

      var charcode = str.charCodeAt(i);

      // Position 0 - 127 is equal to percent-encoding with an ASCII character encoding:
      if (charcode < 128) {
        encoded = encoded + o2.escape.getHex(charcode);
      }

      // Position 128 - 2047: two bytes for UTF-8 character encoding.
      if (charcode > 127 && charcode < 2048) {
        // First UTF byte: Mask the first five bits of charcode with binary 110X.XXXX:
        encoded = encoded + o2.escape.getHex((charcode >> 6) | 0xC0);
        // Second UTF byte: Get last six bits of charcode and mask them with binary 10XX.XXXX:
        encoded = encoded + o2.escape.getHex((charcode & 0x3F) | 0x80);
      }

      // Position 2048 - 65535: three bytes for UTF-8 character encoding.
      if (charcode > 2047 && charcode < 65536) {
        // First UTF byte: Mask the first four bits of charcode with binary 1110.XXXX:
        encoded = encoded + o2.escape.getHex((charcode >> 12) | 0xE0);
        // Second UTF byte: Get the next six bits of charcode and mask them binary 10XX.XXXX:
        encoded = encoded + o2.escape.getHex(((charcode >> 6) & 0x3F) | 0x80);
        // Third UTF byte: Get the last six bits of charcode and mask them binary 10XX.XXXX:
        encoded = encoded + o2.escape.getHex((charcode & 0x3F) | 0x80);
      }

      // Position 65536 - : four bytes for UTF-8 character encoding.
      if (charcode > 65535) {
        // First UTF byte: Mask the first three bits of charcode with binary 1111.0XXX:
        encoded = encoded + o2.escape.getHex((charcode >> 18) | 0xF0);
        // Second UTF byte: Get the next six bits of charcode and mask them binary 10XX.XXXX:
        encoded = encoded + o2.escape.getHex(((charcode >> 12) & 0x3F) | 0x80);
        // Third UTF byte: Get the last six bits of charcode and mask them binary 10XX.XXXX:
        encoded = encoded + o2.escape.getHex(((charcode >> 6) & 0x3F) | 0x80);
        // Fourth UTF byte: Get the last six bits of charcode and mask them binary 10XX.XXXX:
        encoded = encoded + o2.escape.getHex((charcode & 0x3F) | 0x80);
      }

    }
  }
  // console.log(encoded);
  return encoded;
}

o2.escape.unescape = function(encoded) {
  var decoded = "";
  // Remember characters that are not allowed in a URL:
  var notallowed = "";
  // Remember illegal percent encoding:
  var illegalencoding = "";

  // UTF-8 bytes from left to right:
  var byte1, byte2, byte3, byte4 = 0;

  var i = 0;
  while (i < encoded.length) {
    var ch = encoded.charAt(i);
    // Check for percent-encoded string:
    if (ch == "%") {

      // Check for legal percent-encoding of first byte:
      if (o2.escape.getDec(encoded.substr(i,3)) < 255) {

        // Get the decimal values of all (potential) UTF-bytes:
        byte1 = o2.escape.getDec(encoded.substr(i,3));
        byte2 = o2.escape.getDec(encoded.substr(i+3,3));
        byte3 = o2.escape.getDec(encoded.substr(i+6,3));
        byte4 = o2.escape.getDec(encoded.substr(i+9,3));

        // Check for one byte UTF-8 character encoding:
        if (byte1 < 128) {
          decoded = decoded + String.fromCharCode(byte1);
          i = i + 3;
        }

        // Check for illegal one byte UTF-8 character encoding:
        if (byte1 > 127 && byte1 < 192) {
          decoded = decoded + encoded.substr(i,3);
          illegalencoding = illegalencoding + encoded.substr(i,3) + " ";
          i = i + 3;
        }

        // Check for two byte UTF-8 character encoding:
        if (byte1 > 191 && byte1 < 224) {
          if (byte2 > 127 && byte2 < 192) {
            decoded = decoded + String.fromCharCode(((byte1 & 0x1F) << 6) | (byte2 & 0x3F));
          }
          else {
            decoded = decoded + encoded.substr(i,6);
            illegalencoding = illegalencoding + encoded.substr(i,6) + " ";
          }
          i = i + 6;
        }

        // Check for three byte UTF-8 character encoding:
        if (byte1 > 223 && byte1 < 240) {
          if (byte2 > 127 && byte2 < 192) {
            if (byte3 > 127 && byte3 < 192) {
              decoded = decoded + String.fromCharCode(((byte1 & 0xF) << 12) | ((byte2 & 0x3F) << 6) | (byte3 & 0x3F));
            }
            else {
              decoded = decoded + encoded.substr(i,9);
              illegalencoding = illegalencoding + encoded.substr(i,9) + " ";
            }
          }
          else {
            decoded = decoded + encoded.substr(i,9);
            illegalencoding = illegalencoding + encoded.substr(i,9) + " ";
          }
          i = i + 9;
        }

        // Check for four byte UTF-8 character encoding:
        if (byte1 > 239) {
          if (byte2 > 127 && byte2 < 192) {
            if (byte3 > 127 && byte3 < 192) {
              if (byte4 > 127 && byte4 < 192) {
                decoded = decoded + String.fromCharCode(((byte1 & 0x7) << 18) | ((byte2 & 0x3F) << 12) | ((byte3 & 0x3F) << 6) | (byte4 & 0x3F));
              }
              else {
                decoded = decoded + encoded.substr(i,12);
                illegalencoding = illegalencoding + encoded.substr(i,12) + " ";
              }
            }
            else {
              decoded = decoded + encoded.substr(i,12);
              illegalencoding = illegalencoding + encoded.substr(i,12) + " ";
            }
          }
          else {
            decoded = decoded + encoded.substr(i,12);
            illegalencoding = illegalencoding + encoded.substr(i,12) + " ";
          }
          i = i + 12;
        }

      }
      else {  // the first byte is not legally percent-encoded
        decoded = decoded + encoded.substr(i,3);
        illegalencoding = illegalencoding + encoded.substr(i,3) + " ";
        i = i + 3;
      }

    }
    else {  // the string is not percent encoded
      // Check if character is an allowed character:
      if (allowed.indexOf(ch) == -1) notallowed = notallowed + ch + " ";
      decoded = decoded + ch;
      i++;
    }
  }  // end of while ...
  return decoded;
}

o2.escape.getHex = function(decimal) {
  return "%" + hexchars.charAt(decimal >> 4) + hexchars.charAt(decimal & 0xF);
}

// This function returns the decimal value of two hexadecimal digits.
// Input is a percent sign followed by two hexadecimal digits. If the input
// string is shorter than three characters, the percent sign is missing or if
// not a hexadecimal numeral is used, then the decimal value 256 is returned:
o2.escape.getDec = function(hexencoded) {
  if (hexencoded.length == 3) {
    if (hexencoded.charAt(0) == "%") {
      if (hexchars.indexOf(hexencoded.charAt(1)) != -1 && hexchars.indexOf(hexencoded.charAt(2)) != -1) {
        return parseInt(hexencoded.substr(1,2),16);
      }
    }
  }
  return 256;
}
