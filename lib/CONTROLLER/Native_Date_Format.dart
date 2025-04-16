class CustomDateFormat {
  static String format(DateTime dateTime, String pattern) {
    String result = pattern;
    if (result.contains('yyyy')) {
      result =
          result.replaceAll('yyyy', dateTime.year.toString().padLeft(4, '0'));
    }
    if (result.contains('MM')) {
      result =
          result.replaceAll('MM', dateTime.month.toString().padLeft(2, '0'));
    } else if (result.contains('M')) {
      result = result.replaceAll('M', dateTime.month.toString());
    }
    if (result.contains('dd')) {
      result = result.replaceAll('dd', dateTime.day.toString().padLeft(2, '0'));
    } else if (result.contains('d')) {
      result = result.replaceAll('d', dateTime.day.toString());
    }
    if (result.contains('hh')) {
      int hour12 = dateTime.hour % 12;
      if (hour12 == 0) hour12 = 12;
      result = result.replaceAll('hh', hour12.toString().padLeft(2, '0'));
    } else if (result.contains('h')) {
      int hour12 = dateTime.hour % 12;
      if (hour12 == 0) hour12 = 12;
      result = result.replaceAll('h', hour12.toString());
    }
    if (result.contains('HH')) {
      result =
          result.replaceAll('HH', dateTime.hour.toString().padLeft(2, '0'));
    } else if (result.contains('H')) {
      result = result.replaceAll('H', dateTime.hour.toString());
    }
    if (result.contains('mm')) {
      result =
          result.replaceAll('mm', dateTime.minute.toString().padLeft(2, '0'));
    } else if (result.contains('m')) {
      result = result.replaceAll('m', dateTime.minute.toString());
    }
    if (result.contains('ss')) {
      result =
          result.replaceAll('ss', dateTime.second.toString().padLeft(2, '0'));
    } else if (result.contains('s')) {
      result = result.replaceAll('s', dateTime.second.toString());
    }
    if (result.contains('a')) {
      result = result.replaceAll('a', dateTime.hour < 12 ? 'AM' : 'PM');
    }
    return result;
  }

  static String formatDateTime(DateTime dateTime) {
    return format(dateTime, 'yyyy-MM-dd hh:mm a');
  }
}
