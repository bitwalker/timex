defmodule Timex.Timezone.Local do
  @moduledoc """
  Contains the logic and parser for extracting local timezone configuration.
  """
  alias Timex.DateTime, as: DateTime
  alias Timex.Date,     as: Date

  # Map of Windows time zone names to Olson time zone names
  @lookup_olson [
    { "AUS Central Standard Time", "Australia/Darwin" },
    { "AUS Eastern Standard Time", "Australia/Sydney" },
    { "Afghanistan Standard Time", "Asia/Kabul" },
    { "Alaskan Standard Time", "America/Anchorage" },
    { "Arab Standard Time", "Asia/Riyadh" },
    { "Arabian Standard Time", "Asia/Dubai" },
    { "Arabic Standard Time", "Asia/Baghdad" },
    { "Argentina Standard Time", "America/Buenos_Aires" },
    { "Atlantic Standard Time", "America/Halifax" },
    { "Azerbaijan Standard Time", "Asia/Baku" },
    { "Azores Standard Time", "Atlantic/Azores" },
    { "Bahia Standard Time", "America/Bahia" },
    { "Bangladesh Standard Time", "Asia/Dhaka" },
    { "Canada Central Standard Time", "America/Regina" },
    { "Cape Verde Standard Time", "Atlantic/Cape_Verde" },
    { "Caucasus Standard Time", "Asia/Yerevan" },
    { "Cen. Australia Standard Time", "Australia/Adelaide" },
    { "Central America Standard Time", "America/Guatemala" },
    { "Central Asia Standard Time", "Asia/Almaty" },
    { "Central Brazilian Standard Time", "America/Cuiaba" },
    { "Central Europe Standard Time", "Europe/Budapest" },
    { "Central European Standard Time", "Europe/Warsaw" },
    { "Central Pacific Standard Time", "Pacific/Guadalcanal" },
    { "Central Standard Time", "America/Chicago" },
    { "Central Standard Time (Mexico)", "America/Mexico_City" },
    { "China Standard Time", "Asia/Shanghai" },
    { "Dateline Standard Time", "Etc/GMT+12" },
    { "E. Africa Standard Time", "Africa/Nairobi" },
    { "E. Australia Standard Time", "Australia/Brisbane" },
    { "E. Europe Standard Time", "Asia/Nicosia" },
    { "E. South America Standard Time", "America/Sao_Paulo" },
    { "Eastern Standard Time", "America/New_York" },
    { "Egypt Standard Time", "Africa/Cairo" },
    { "Ekaterinburg Standard Time", "Asia/Yekaterinburg" },
    { "FLE Standard Time", "Europe/Kiev" },
    { "Fiji Standard Time", "Pacific/Fiji" },
    { "GMT Standard Time", "Europe/London" },
    { "GTB Standard Time", "Europe/Bucharest" },
    { "Georgian Standard Time", "Asia/Tbilisi" },
    { "Greenland Standard Time", "America/Godthab" },
    { "Greenwich Standard Time", "Atlantic/Reykjavik" },
    { "Hawaiian Standard Time", "Pacific/Honolulu" },
    { "India Standard Time", "Asia/Calcutta" },
    { "Iran Standard Time", "Asia/Tehran" },
    { "Israel Standard Time", "Asia/Jerusalem" },
    { "Jordan Standard Time", "Asia/Amman" },
    { "Kaliningrad Standard Time", "Europe/Kaliningrad" },
    { "Korea Standard Time", "Asia/Seoul" },
    { "Libya Standard Time", "Africa/Tripoli" },
    { "Magadan Standard Time", "Asia/Magadan" },
    { "Mauritius Standard Time", "Indian/Mauritius" },
    { "Middle East Standard Time", "Asia/Beirut" },
    { "Montevideo Standard Time", "America/Montevideo" },
    { "Morocco Standard Time", "Africa/Casablanca" },
    { "Mountain Standard Time", "America/Denver" },
    { "Mountain Standard Time (Mexico)", "America/Chihuahua" },
    { "Myanmar Standard Time", "Asia/Rangoon" },
    { "N. Central Asia Standard Time", "Asia/Novosibirsk" },
    { "Namibia Standard Time", "Africa/Windhoek" },
    { "Nepal Standard Time", "Asia/Katmandu" },
    { "New Zealand Standard Time", "Pacific/Auckland" },
    { "Newfoundland Standard Time", "America/St_Johns" },
    { "North Asia East Standard Time", "Asia/Irkutsk" },
    { "North Asia Standard Time", "Asia/Krasnoyarsk" },
    { "Pacific SA Standard Time", "America/Santiago" },
    { "Pacific Standard Time", "America/Los_Angeles" },
    { "Pacific Standard Time (Mexico)", "America/Santa_Isabel" },
    { "Pakistan Standard Time", "Asia/Karachi" },
    { "Paraguay Standard Time", "America/Asuncion" },
    { "Romance Standard Time", "Europe/Paris" },
    { "Russian Standard Time", "Europe/Moscow" },
    { "SA Eastern Standard Time", "America/Cayenne" },
    { "SA Pacific Standard Time", "America/Bogota" },
    { "SA Western Standard Time", "America/La_Paz" },
    { "SE Asia Standard Time", "Asia/Bangkok" },
    { "Samoa Standard Time", "Pacific/Apia" },
    { "Singapore Standard Time", "Asia/Singapore" },
    { "South Africa Standard Time", "Africa/Johannesburg" },
    { "Sri Lanka Standard Time", "Asia/Colombo" },
    { "Syria Standard Time", "Asia/Damascus" },
    { "Taipei Standard Time", "Asia/Taipei" },
    { "Tasmania Standard Time", "Australia/Hobart" },
    { "Tokyo Standard Time", "Asia/Tokyo" },
    { "Tonga Standard Time", "Pacific/Tongatapu" },
    { "Turkey Standard Time", "Europe/Istanbul" },
    { "US Eastern Standard Time", "America/Indianapolis" },
    { "US Mountain Standard Time", "America/Phoenix" },
    { "UTC", "Etc/GMT" },
    { "UTC+12", "Etc/GMT-12" },
    { "UTC-02", "Etc/GMT+2" },
    { "UTC-11", "Etc/GMT+11" },
    { "Ulaanbaatar Standard Time", "Asia/Ulaanbaatar" },
    { "Venezuela Standard Time", "America/Caracas" },
    { "Vladivostok Standard Time", "Asia/Vladivostok" },
    { "W. Australia Standard Time", "Australia/Perth" },
    { "W. Central Africa Standard Time", "Africa/Lagos" },
    { "W. Europe Standard Time", "Europe/Berlin" },
    { "West Asia Standard Time", "Asia/Tashkent" },
    { "West Pacific Standard Time", "Pacific/Port_Moresby" },
    { "Yakutsk Standard Time", "Asia/Yakutsk" }
  ]

  # Reverse lookup from Olson time zone names to Windows time zone names
  @lookup_win [
    { "Africa/Abidjan", "Greenwich Standard Time" },
    { "Africa/Accra", "Greenwich Standard Time" },
    { "Africa/Addis_Ababa", "E. Africa Standard Time" },
    { "Africa/Algiers", "W. Central Africa Standard Time" },
    { "Africa/Asmera", "E. Africa Standard Time" },
    { "Africa/Bamako", "Greenwich Standard Time" },
    { "Africa/Bangui", "W. Central Africa Standard Time" },
    { "Africa/Banjul", "Greenwich Standard Time" },
    { "Africa/Bissau", "Greenwich Standard Time" },
    { "Africa/Blantyre", "South Africa Standard Time" },
    { "Africa/Brazzaville", "W. Central Africa Standard Time" },
    { "Africa/Bujumbura", "South Africa Standard Time" },
    { "Africa/Cairo", "Egypt Standard Time" },
    { "Africa/Casablanca", "Morocco Standard Time" },
    { "Africa/Ceuta", "Romance Standard Time" },
    { "Africa/Conakry", "Greenwich Standard Time" },
    { "Africa/Dakar", "Greenwich Standard Time" },
    { "Africa/Dar_es_Salaam", "E. Africa Standard Time" },
    { "Africa/Djibouti", "E. Africa Standard Time" },
    { "Africa/Douala", "W. Central Africa Standard Time" },
    { "Africa/El_Aaiun", "Morocco Standard Time" },
    { "Africa/Freetown", "Greenwich Standard Time" },
    { "Africa/Gaborone", "South Africa Standard Time" },
    { "Africa/Harare", "South Africa Standard Time" },
    { "Africa/Johannesburg", "South Africa Standard Time" },
    { "Africa/Juba", "E. Africa Standard Time" },
    { "Africa/Kampala", "E. Africa Standard Time" },
    { "Africa/Khartoum", "E. Africa Standard Time" },
    { "Africa/Kigali", "South Africa Standard Time" },
    { "Africa/Kinshasa", "W. Central Africa Standard Time" },
    { "Africa/Lagos", "W. Central Africa Standard Time" },
    { "Africa/Libreville", "W. Central Africa Standard Time" },
    { "Africa/Lome", "Greenwich Standard Time" },
    { "Africa/Luanda", "W. Central Africa Standard Time" },
    { "Africa/Lubumbashi", "South Africa Standard Time" },
    { "Africa/Lusaka", "South Africa Standard Time" },
    { "Africa/Malabo", "W. Central Africa Standard Time" },
    { "Africa/Maputo", "South Africa Standard Time" },
    { "Africa/Maseru", "South Africa Standard Time" },
    { "Africa/Mbabane", "South Africa Standard Time" },
    { "Africa/Mogadishu", "E. Africa Standard Time" },
    { "Africa/Monrovia", "Greenwich Standard Time" },
    { "Africa/Nairobi", "E. Africa Standard Time" },
    { "Africa/Ndjamena", "W. Central Africa Standard Time" },
    { "Africa/Niamey", "W. Central Africa Standard Time" },
    { "Africa/Nouakchott", "Greenwich Standard Time" },
    { "Africa/Ouagadougou", "Greenwich Standard Time" },
    { "Africa/Porto-Novo", "W. Central Africa Standard Time" },
    { "Africa/Sao_Tome", "Greenwich Standard Time" },
    { "Africa/Tripoli", "Libya Standard Time" },
    { "Africa/Tunis", "W. Central Africa Standard Time" },
    { "Africa/Windhoek", "Namibia Standard Time" },
    { "America/Anchorage", "Alaskan Standard Time" },
    { "America/Anguilla", "SA Western Standard Time" },
    { "America/Antigua", "SA Western Standard Time" },
    { "America/Araguaina", "SA Eastern Standard Time" },
    { "America/Argentina/La_Rioja", "Argentina Standard Time" },
    { "America/Argentina/Rio_Gallegos", "Argentina Standard Time" },
    { "America/Argentina/Salta", "Argentina Standard Time" },
    { "America/Argentina/San_Juan", "Argentina Standard Time" },
    { "America/Argentina/San_Luis", "Argentina Standard Time" },
    { "America/Argentina/Tucuman", "Argentina Standard Time" },
    { "America/Argentina/Ushuaia", "Argentina Standard Time" },
    { "America/Aruba", "SA Western Standard Time" },
    { "America/Asuncion", "Paraguay Standard Time" },
    { "America/Bahia", "Bahia Standard Time" },
    { "America/Bahia_Banderas", "Central Standard Time (Mexico)" },
    { "America/Barbados", "SA Western Standard Time" },
    { "America/Belem", "SA Eastern Standard Time" },
    { "America/Belize", "Central America Standard Time" },
    { "America/Blanc-Sablon", "SA Western Standard Time" },
    { "America/Boa_Vista", "SA Western Standard Time" },
    { "America/Bogota", "SA Pacific Standard Time" },
    { "America/Boise", "Mountain Standard Time" },
    { "America/Buenos_Aires", "Argentina Standard Time" },
    { "America/Cambridge_Bay", "Mountain Standard Time" },
    { "America/Campo_Grande", "Central Brazilian Standard Time" },
    { "America/Cancun", "Central Standard Time (Mexico)" },
    { "America/Caracas", "Venezuela Standard Time" },
    { "America/Catamarca", "Argentina Standard Time" },
    { "America/Cayenne", "SA Eastern Standard Time" },
    { "America/Cayman", "SA Pacific Standard Time" },
    { "America/Chicago", "Central Standard Time" },
    { "America/Chihuahua", "Mountain Standard Time (Mexico)" },
    { "America/Coral_Harbour", "SA Pacific Standard Time" },
    { "America/Cordoba", "Argentina Standard Time" },
    { "America/Costa_Rica", "Central America Standard Time" },
    { "America/Creston", "US Mountain Standard Time" },
    { "America/Cuiaba", "Central Brazilian Standard Time" },
    { "America/Curacao", "SA Western Standard Time" },
    { "America/Danmarkshavn", "UTC" },
    { "America/Dawson", "Pacific Standard Time" },
    { "America/Dawson_Creek", "US Mountain Standard Time" },
    { "America/Denver", "Mountain Standard Time" },
    { "America/Detroit", "Eastern Standard Time" },
    { "America/Dominica", "SA Western Standard Time" },
    { "America/Edmonton", "Mountain Standard Time" },
    { "America/Eirunepe", "SA Pacific Standard Time" },
    { "America/El_Salvador", "Central America Standard Time" },
    { "America/Fortaleza", "SA Eastern Standard Time" },
    { "America/Glace_Bay", "Atlantic Standard Time" },
    { "America/Godthab", "Greenland Standard Time" },
    { "America/Goose_Bay", "Atlantic Standard Time" },
    { "America/Grand_Turk", "Eastern Standard Time" },
    { "America/Grenada", "SA Western Standard Time" },
    { "America/Guadeloupe", "SA Western Standard Time" },
    { "America/Guatemala", "Central America Standard Time" },
    { "America/Guayaquil", "SA Pacific Standard Time" },
    { "America/Guyana", "SA Western Standard Time" },
    { "America/Halifax", "Atlantic Standard Time" },
    { "America/Havana", "Eastern Standard Time" },
    { "America/Hermosillo", "US Mountain Standard Time" },
    { "America/Indiana/Knox", "Central Standard Time" },
    { "America/Indiana/Marengo", "US Eastern Standard Time" },
    { "America/Indiana/Petersburg", "Eastern Standard Time" },
    { "America/Indiana/Tell_City", "Central Standard Time" },
    { "America/Indiana/Vevay", "US Eastern Standard Time" },
    { "America/Indiana/Vincennes", "Eastern Standard Time" },
    { "America/Indiana/Winamac", "Eastern Standard Time" },
    { "America/Indianapolis", "US Eastern Standard Time" },
    { "America/Inuvik", "Mountain Standard Time" },
    { "America/Iqaluit", "Eastern Standard Time" },
    { "America/Jamaica", "SA Pacific Standard Time" },
    { "America/Jujuy", "Argentina Standard Time" },
    { "America/Juneau", "Alaskan Standard Time" },
    { "America/Kentucky/Monticello", "Eastern Standard Time" },
    { "America/Kralendijk", "SA Western Standard Time" },
    { "America/La_Paz", "SA Western Standard Time" },
    { "America/Lima", "SA Pacific Standard Time" },
    { "America/Los_Angeles", "Pacific Standard Time" },
    { "America/Louisville", "Eastern Standard Time" },
    { "America/Lower_Princes", "SA Western Standard Time" },
    { "America/Maceio", "SA Eastern Standard Time" },
    { "America/Managua", "Central America Standard Time" },
    { "America/Manaus", "SA Western Standard Time" },
    { "America/Marigot", "SA Western Standard Time" },
    { "America/Martinique", "SA Western Standard Time" },
    { "America/Matamoros", "Central Standard Time" },
    { "America/Mazatlan", "Mountain Standard Time (Mexico)" },
    { "America/Mendoza", "Argentina Standard Time" },
    { "America/Menominee", "Central Standard Time" },
    { "America/Merida", "Central Standard Time (Mexico)" },
    { "America/Mexico_City", "Central Standard Time (Mexico)" },
    { "America/Moncton", "Atlantic Standard Time" },
    { "America/Monterrey", "Central Standard Time (Mexico)" },
    { "America/Montevideo", "Montevideo Standard Time" },
    { "America/Montreal", "Eastern Standard Time" },
    { "America/Montserrat", "SA Western Standard Time" },
    { "America/Nassau", "Eastern Standard Time" },
    { "America/New_York", "Eastern Standard Time" },
    { "America/Nipigon", "Eastern Standard Time" },
    { "America/Nome", "Alaskan Standard Time" },
    { "America/Noronha", "UTC-02" },
    { "America/North_Dakota/Beulah", "Central Standard Time" },
    { "America/North_Dakota/Center", "Central Standard Time" },
    { "America/North_Dakota/New_Salem", "Central Standard Time" },
    { "America/Ojinaga", "Mountain Standard Time" },
    { "America/Panama", "SA Pacific Standard Time" },
    { "America/Pangnirtung", "Eastern Standard Time" },
    { "America/Paramaribo", "SA Eastern Standard Time" },
    { "America/Phoenix", "US Mountain Standard Time" },
    { "America/Port-au-Prince", "Eastern Standard Time" },
    { "America/Port_of_Spain", "SA Western Standard Time" },
    { "America/Porto_Velho", "SA Western Standard Time" },
    { "America/Puerto_Rico", "SA Western Standard Time" },
    { "America/Rainy_River", "Central Standard Time" },
    { "America/Rankin_Inlet", "Central Standard Time" },
    { "America/Recife", "SA Eastern Standard Time" },
    { "America/Regina", "Canada Central Standard Time" },
    { "America/Resolute", "Central Standard Time" },
    { "America/Rio_Branco", "SA Pacific Standard Time" },
    { "America/Santa_Isabel", "Pacific Standard Time (Mexico)" },
    { "America/Santarem", "SA Eastern Standard Time" },
    { "America/Santiago", "Pacific SA Standard Time" },
    { "America/Santo_Domingo", "SA Western Standard Time" },
    { "America/Sao_Paulo", "E. South America Standard Time" },
    { "America/Scoresbysund", "Azores Standard Time" },
    { "America/Shiprock", "Mountain Standard Time" },
    { "America/Sitka", "Alaskan Standard Time" },
    { "America/St_Barthelemy", "SA Western Standard Time" },
    { "America/St_Johns", "Newfoundland Standard Time" },
    { "America/St_Kitts", "SA Western Standard Time" },
    { "America/St_Lucia", "SA Western Standard Time" },
    { "America/St_Thomas", "SA Western Standard Time" },
    { "America/St_Vincent", "SA Western Standard Time" },
    { "America/Swift_Current", "Canada Central Standard Time" },
    { "America/Tegucigalpa", "Central America Standard Time" },
    { "America/Thule", "Atlantic Standard Time" },
    { "America/Thunder_Bay", "Eastern Standard Time" },
    { "America/Tijuana", "Pacific Standard Time" },
    { "America/Toronto", "Eastern Standard Time" },
    { "America/Tortola", "SA Western Standard Time" },
    { "America/Vancouver", "Pacific Standard Time" },
    { "America/Whitehorse", "Pacific Standard Time" },
    { "America/Winnipeg", "Central Standard Time" },
    { "America/Yakutat", "Alaskan Standard Time" },
    { "America/Yellowknife", "Mountain Standard Time" },
    { "Antarctica/Casey", "W. Australia Standard Time" },
    { "Antarctica/Davis", "SE Asia Standard Time" },
    { "Antarctica/DumontDUrville", "West Pacific Standard Time" },
    { "Antarctica/Macquarie", "Central Pacific Standard Time" },
    { "Antarctica/Mawson", "West Asia Standard Time" },
    { "Antarctica/McMurdo", "New Zealand Standard Time" },
    { "Antarctica/Palmer", "Pacific SA Standard Time" },
    { "Antarctica/Rothera", "SA Eastern Standard Time" },
    { "Antarctica/South_Pole", "New Zealand Standard Time" },
    { "Antarctica/Syowa", "E. Africa Standard Time" },
    { "Antarctica/Vostok", "Central Asia Standard Time" },
    { "Arctic/Longyearbyen", "W. Europe Standard Time" },
    { "Asia/Aden", "Arab Standard Time" },
    { "Asia/Almaty", "Central Asia Standard Time" },
    { "Asia/Amman", "Jordan Standard Time" },
    { "Asia/Anadyr", "Magadan Standard Time" },
    { "Asia/Aqtau", "West Asia Standard Time" },
    { "Asia/Aqtobe", "West Asia Standard Time" },
    { "Asia/Ashgabat", "West Asia Standard Time" },
    { "Asia/Baghdad", "Arabic Standard Time" },
    { "Asia/Bahrain", "Arab Standard Time" },
    { "Asia/Baku", "Azerbaijan Standard Time" },
    { "Asia/Bangkok", "SE Asia Standard Time" },
    { "Asia/Beirut", "Middle East Standard Time" },
    { "Asia/Bishkek", "Central Asia Standard Time" },
    { "Asia/Brunei", "Singapore Standard Time" },
    { "Asia/Calcutta", "India Standard Time" },
    { "Asia/Choibalsan", "Ulaanbaatar Standard Time" },
    { "Asia/Chongqing", "China Standard Time" },
    { "Asia/Colombo", "Sri Lanka Standard Time" },
    { "Asia/Damascus", "Syria Standard Time" },
    { "Asia/Dhaka", "Bangladesh Standard Time" },
    { "Asia/Dili", "Tokyo Standard Time" },
    { "Asia/Dubai", "Arabian Standard Time" },
    { "Asia/Dushanbe", "West Asia Standard Time" },
    { "Asia/Harbin", "China Standard Time" },
    { "Asia/Hong_Kong", "China Standard Time" },
    { "Asia/Hovd", "SE Asia Standard Time" },
    { "Asia/Irkutsk", "North Asia East Standard Time" },
    { "Asia/Jakarta", "SE Asia Standard Time" },
    { "Asia/Jayapura", "Tokyo Standard Time" },
    { "Asia/Jerusalem", "Israel Standard Time" },
    { "Asia/Kabul", "Afghanistan Standard Time" },
    { "Asia/Kamchatka", "Magadan Standard Time" },
    { "Asia/Karachi", "Pakistan Standard Time" },
    { "Asia/Kashgar", "China Standard Time" },
    { "Asia/Katmandu", "Nepal Standard Time" },
    { "Asia/Khandyga", "Yakutsk Standard Time" },
    { "Asia/Krasnoyarsk", "North Asia Standard Time" },
    { "Asia/Kuala_Lumpur", "Singapore Standard Time" },
    { "Asia/Kuching", "Singapore Standard Time" },
    { "Asia/Kuwait", "Arab Standard Time" },
    { "Asia/Macau", "China Standard Time" },
    { "Asia/Magadan", "Magadan Standard Time" },
    { "Asia/Makassar", "Singapore Standard Time" },
    { "Asia/Manila", "Singapore Standard Time" },
    { "Asia/Muscat", "Arabian Standard Time" },
    { "Asia/Nicosia", "E. Europe Standard Time" },
    { "Asia/Novokuznetsk", "N. Central Asia Standard Time" },
    { "Asia/Novosibirsk", "N. Central Asia Standard Time" },
    { "Asia/Omsk", "N. Central Asia Standard Time" },
    { "Asia/Oral", "West Asia Standard Time" },
    { "Asia/Phnom_Penh", "SE Asia Standard Time" },
    { "Asia/Pontianak", "SE Asia Standard Time" },
    { "Asia/Pyongyang", "Korea Standard Time" },
    { "Asia/Qatar", "Arab Standard Time" },
    { "Asia/Qyzylorda", "Central Asia Standard Time" },
    { "Asia/Rangoon", "Myanmar Standard Time" },
    { "Asia/Riyadh", "Arab Standard Time" },
    { "Asia/Saigon", "SE Asia Standard Time" },
    { "Asia/Sakhalin", "Vladivostok Standard Time" },
    { "Asia/Samarkand", "West Asia Standard Time" },
    { "Asia/Seoul", "Korea Standard Time" },
    { "Asia/Shanghai", "China Standard Time" },
    { "Asia/Singapore", "Singapore Standard Time" },
    { "Asia/Taipei", "Taipei Standard Time" },
    { "Asia/Tashkent", "West Asia Standard Time" },
    { "Asia/Tbilisi", "Georgian Standard Time" },
    { "Asia/Tehran", "Iran Standard Time" },
    { "Asia/Thimphu", "Bangladesh Standard Time" },
    { "Asia/Tokyo", "Tokyo Standard Time" },
    { "Asia/Ulaanbaatar", "Ulaanbaatar Standard Time" },
    { "Asia/Urumqi", "China Standard Time" },
    { "Asia/Ust-Nera", "Vladivostok Standard Time" },
    { "Asia/Vientiane", "SE Asia Standard Time" },
    { "Asia/Vladivostok", "Vladivostok Standard Time" },
    { "Asia/Yakutsk", "Yakutsk Standard Time" },
    { "Asia/Yekaterinburg", "Ekaterinburg Standard Time" },
    { "Asia/Yerevan", "Caucasus Standard Time" },
    { "Atlantic/Azores", "Azores Standard Time" },
    { "Atlantic/Bermuda", "Atlantic Standard Time" },
    { "Atlantic/Canary", "GMT Standard Time" },
    { "Atlantic/Cape_Verde", "Cape Verde Standard Time" },
    { "Atlantic/Faeroe", "GMT Standard Time" },
    { "Atlantic/Madeira", "GMT Standard Time" },
    { "Atlantic/Reykjavik", "Greenwich Standard Time" },
    { "Atlantic/South_Georgia", "UTC-02" },
    { "Atlantic/St_Helena", "Greenwich Standard Time" },
    { "Atlantic/Stanley", "SA Eastern Standard Time" },
    { "Australia/Adelaide", "Cen. Australia Standard Time" },
    { "Australia/Brisbane", "E. Australia Standard Time" },
    { "Australia/Broken_Hill", "Cen. Australia Standard Time" },
    { "Australia/Currie", "Tasmania Standard Time" },
    { "Australia/Darwin", "AUS Central Standard Time" },
    { "Australia/Hobart", "Tasmania Standard Time" },
    { "Australia/Lindeman", "E. Australia Standard Time" },
    { "Australia/Melbourne", "AUS Eastern Standard Time" },
    { "Australia/Perth", "W. Australia Standard Time" },
    { "Australia/Sydney", "AUS Eastern Standard Time" },
    { "CST6CDT", "Central Standard Time" },
    { "EST5EDT", "Eastern Standard Time" },
    { "Etc/GMT", "UTC" },
    { "Etc/GMT+1", "Cape Verde Standard Time" },
    { "Etc/GMT+10", "Hawaiian Standard Time" },
    { "Etc/GMT+11", "UTC+11" },
    { "Etc/GMT+12", "Dateline Standard Time" },
    { "Etc/GMT+2", "UTC+02" },
    { "Etc/GMT+3", "SA Eastern Standard Time" },
    { "Etc/GMT+4", "SA Western Standard Time" },
    { "Etc/GMT+5", "SA Pacific Standard Time" },
    { "Etc/GMT+6", "Central America Standard Time" },
    { "Etc/GMT+7", "US Mountain Standard Time" },
    { "Etc/GMT-1", "W. Central Africa Standard Time" },
    { "Etc/GMT-10", "West Pacific Standard Time" },
    { "Etc/GMT-11", "Central Pacific Standard Time" },
    { "Etc/GMT-12", "GMT+12" },
    { "Etc/GMT-13", "Tonga Standard Time" },
    { "Etc/GMT-2", "South Africa Standard Time" },
    { "Etc/GMT-3", "E. Africa Standard Time" },
    { "Etc/GMT-4", "Arabian Standard Time" },
    { "Etc/GMT-5", "West Asia Standard Time" },
    { "Etc/GMT-6", "Central Asia Standard Time" },
    { "Etc/GMT-7", "SE Asia Standard Time" },
    { "Etc/GMT-8", "Singapore Standard Time" },
    { "Etc/GMT-9", "Tokyo Standard Time" },
    { "Etc/UTC", "UTC" },
    { "Europe/Amsterdam", "W. Europe Standard Time" },
    { "Europe/Andorra", "W. Europe Standard Time" },
    { "Europe/Athens", "GTB Standard Time" },
    { "Europe/Belgrade", "Central Europe Standard Time" },
    { "Europe/Berlin", "W. Europe Standard Time" },
    { "Europe/Bratislava", "Central Europe Standard Time" },
    { "Europe/Brussels", "Romance Standard Time" },
    { "Europe/Bucharest", "GTB Standard Time" },
    { "Europe/Budapest", "Central Europe Standard Time" },
    { "Europe/Busingen", "W. Europe Standard Time" },
    { "Europe/Chisinau", "GTB Standard Time" },
    { "Europe/Copenhagen", "Romance Standard Time" },
    { "Europe/Dublin", "GMT Standard Time" },
    { "Europe/Gibraltar", "W. Europe Standard Time" },
    { "Europe/Guernsey", "GMT Standard Time" },
    { "Europe/Helsinki", "FLE Standard Time" },
    { "Europe/Isle_of_Man", "GMT Standard Time" },
    { "Europe/Istanbul", "Turkey Standard Time" },
    { "Europe/Jersey", "GMT Standard Time" },
    { "Europe/Kaliningrad", "Kaliningrad Standard Time" },
    { "Europe/Kiev", "FLE Standard Time" },
    { "Europe/Lisbon", "GMT Standard Time" },
    { "Europe/Ljubljana", "Central Europe Standard Time" },
    { "Europe/London", "GMT Standard Time" },
    { "Europe/Luxembourg", "W. Europe Standard Time" },
    { "Europe/Madrid", "Romance Standard Time" },
    { "Europe/Malta", "W. Europe Standard Time" },
    { "Europe/Mariehamn", "FLE Standard Time" },
    { "Europe/Minsk", "Kaliningrad Standard Time" },
    { "Europe/Monaco", "W. Europe Standard Time" },
    { "Europe/Moscow", "Russian Standard Time" },
    { "Europe/Oslo", "W. Europe Standard Time" },
    { "Europe/Paris", "Romance Standard Time" },
    { "Europe/Podgorica", "Central Europe Standard Time" },
    { "Europe/Prague", "Central Europe Standard Time" },
    { "Europe/Riga", "FLE Standard Time" },
    { "Europe/Rome", "W. Europe Standard Time" },
    { "Europe/Samara", "Russian Standard Time" },
    { "Europe/San_Marino", "W. Europe Standard Time" },
    { "Europe/Sarajevo", "Central European Standard Time" },
    { "Europe/Simferopol", "FLE Standard Time" },
    { "Europe/Skopje", "Central European Standard Time" },
    { "Europe/Sofia", "FLE Standard Time" },
    { "Europe/Stockholm", "W. Europe Standard Time" },
    { "Europe/Tallinn", "FLE Standard Time" },
    { "Europe/Tirane", "Central Europe Standard Time" },
    { "Europe/Uzhgorod", "FLE Standard Time" },
    { "Europe/Vaduz", "W. Europe Standard Time" },
    { "Europe/Vatican", "W. Europe Standard Time" },
    { "Europe/Vienna", "W. Europe Standard Time" },
    { "Europe/Vilnius", "FLE Standard Time" },
    { "Europe/Volgograd", "Russian Standard Time" },
    { "Europe/Warsaw", "Central European Standard Time" },
    { "Europe/Zagreb", "Central European Standard Time" },
    { "Europe/Zaporozhye", "FLE Standard Time" },
    { "Europe/Zurich", "W. Europe Standard Time" },
    { "Indian/Antananarivo", "E. Africa Standard Time" },
    { "Indian/Chagos", "Central Asia Standard Time" },
    { "Indian/Christmas", "SE Asia Standard Time" },
    { "Indian/Cocos", "Myanmar Standard Time" },
    { "Indian/Comoro", "E. Africa Standard Time" },
    { "Indian/Kerguelen", "West Asia Standard Time" },
    { "Indian/Mahe", "Mauritius Standard Time" },
    { "Indian/Maldives", "West Asia Standard Time" },
    { "Indian/Mauritius", "Mauritius Standard Time" },
    { "Indian/Mayotte", "E. Africa Standard Time" },
    { "Indian/Reunion", "Mauritius Standard Time" },
    { "MST7MDT", "Mountain Standard Time" },
    { "PST8PDT", "Pacific Standard Time" },
    { "Pacific/Apia", "Samoa Standard Time" },
    { "Pacific/Auckland", "New Zealand Standard Time" },
    { "Pacific/Efate", "Central Pacific Standard Time" },
    { "Pacific/Enderbury", "Tonga Standard Time" },
    { "Pacific/Fakaofo", "Tonga Standard Time" },
    { "Pacific/Fiji", "Fiji Standard Time" },
    { "Pacific/Funafuti", "UTC+12" },
    { "Pacific/Galapagos", "Central America Standard Time" },
    { "Pacific/Guadalcanal", "Central Pacific Standard Time" },
    { "Pacific/Guam", "West Pacific Standard Time" },
    { "Pacific/Honolulu", "Hawaiian Standard Time" },
    { "Pacific/Johnston", "Hawaiian Standard Time" },
    { "Pacific/Kosrae", "Central Pacific Standard Time" },
    { "Pacific/Kwajalein", "UTC+12" },
    { "Pacific/Majuro", "UTC+12" },
    { "Pacific/Midway", "UTC-11" },
    { "Pacific/Nauru", "UTC+12" },
    { "Pacific/Niue", "UTC-11" },
    { "Pacific/Noumea", "Central Pacific Standard Time" },
    { "Pacific/Pago_Pago", "UTC-11" },
    { "Pacific/Palau", "Tokyo Standard Time" },
    { "Pacific/Ponape", "Central Pacific Standard Time" },
    { "Pacific/Port_Moresby", "West Pacific Standard Time" },
    { "Pacific/Rarotonga", "Hawaiian Standard Time" },
    { "Pacific/Saipan", "West Pacific Standard Time" },
    { "Pacific/Tahiti", "Hawaiian Standard Time" },
    { "Pacific/Tarawa", "UTC+12" },
    { "Pacific/Tongatapu", "Tonga Standard Time" },
    { "Pacific/Truk", "West Pacific Standard Time" },
    { "Pacific/Wake", "UTC+12" },
    { "Pacific/Wallis", "UTC+12" }
  ]

  @_ETC_TIMEZONE      "/etc/timezone"
  @_ETC_SYS_CLOCK     "/etc/sysconfig/clock"
  @_ETC_CONF_CLOCK    "/etc/conf.d/clock"
  @_ETC_LOCALTIME     "/etc/localtime"
  @_USR_ETC_LOCALTIME "/usr/local/etc/localtime"

  @doc """
  Looks up the local timezone configuration. Returns the name of a timezone
  in the Olson database.
  """
  @spec lookup(DateTime.t | nil) :: String.t

  def lookup(), do: Date.universal |> lookup
  def lookup(date) do
    case :os.type() do
      {:unix, :darwin} -> localtz(:osx, date)
      {:unix, _}       -> localtz(:unix, date)
      {:nt}            -> localtz(:win, date)
      _                -> raise "Unsupported operating system!"
    end
  end

  # Get the locally configured timezone on OSX systems
  defp localtz(:osx, date) do
    # Allow TZ environment variable to override lookup
    case System.get_env("TZ") do
      nil ->
        # Most accurate local timezone will come from /etc/localtime,
        # since we can lookup proper timezones for arbitrary dates
        case read_timezone_data(nil, @_ETC_LOCALTIME, date) do
          {:ok, tz} -> tz
          _ ->
            # Fallback and ask systemsetup
            tz = System.cmd("systemsetup -gettimezone")
            |> iolist_to_binary
            |> String.strip(?\n)
            |> String.replace("Time Zone: ", "")
            if String.length(tz) > 0 do
              tz
            else
              raise("Unable to find local timezone.")
            end
        end
      tz -> tz
    end
  end

  # Get the locally configured timezone on *NIX systems
  defp localtz(:unix, date) do
    case System.get_env("TZ") do
      # Not found
      nil ->
        # Since that failed, check distro specific config files
        # containing the timezone name. To clean up the code here
        # we're using pipes, even though we may find the value we
        # are looking for on the first try. The way the function
        # defs are set up, if we find a value, it's just passed
        # along through the pipe until we're done. If we don't,
        # this will try each fallback location in order.
        {:ok, tz} = read_timezone_data(@_ETC_TIMEZONE, date)
        |> read_timezone_data(@_ETC_SYS_CLOCK, date)
        |> read_timezone_data(@_ETC_CONF_CLOCK, date)
        |> read_timezone_data(@_ETC_LOCALTIME, date)
        |> read_timezone_data(@_USR_ETC_LOCALTIME, date)
        tz
      tz  -> tz
    end
  end

  # Get the locally configured timezone on Windows systems
  @local_tz_key 'SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation'
  @sys_tz_key   'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones'
  # We ignore the reference date here, since there is no way to lookup
  # transition times for historical/future dates
  defp localtz(:win, _date) do
    # Windows has many of it's own unique time zone names, which can
    # also be translated to the OS's language.
    {:ok, handle} = :win32reg.open(:local_machine)
    :ok           = :win32reg.change_key(handle, @local_tz_key)
    {:ok, values} = :win32reg.values(handle)
    if List.keymember?(values, 'TimeZoneKeyName', 0) do
      # Windows 7/Vista
      # On some systems the string value might be padded with excessive \0 bytes, trim them
      List.keyfind(values, 'TimeZoneKeyName', 0)
      |> iolist_to_binary
      |> String.strip ?\0
    else
      # Windows 2000 or XP
      # This is the localized name:
      localized = List.keyfind(values, 'StandardName', 0)
      # Open the list of timezones to look up the real name:
      :ok            = :win32reg.change_key(handle, @sys_tz_key)
      {:ok, subkeys} = :win32reg.sub_keys(handle)
      # Iterate over each subkey (timezone), and match against the localized name
      tzone = Enum.find subkeys, fn subkey ->
        :ok           = :win32reg.change_key(handle, subkey)
        {:ok, values} = :win32reg.values(handle)
        case List.keyfind(values, 'Std', 0) do
          {_, zone} when zone == localized -> zone
          _ -> nil
        end
      end
      # If we don't have a timezone yet, we've failed,
      # Otherwise, we need to lookup the final timezone name
      # in the dictionary of unique Windows timezone names
      cond do
        tzone == nil -> raise "Could not find Windows time zone configuration!"
        tzone -> 
          timezone = tzone |> iolist_to_binary
          case List.keyfind(@lookup_olson, timezone, 0) do
            nil ->
              # Try appending "Standard Time"
              case List.keyfind(@lookup_olson, "#{timezone} Standard Time", 0) do
                nil   -> raise "Could not find Windows time zone configuration!"
                final -> final
              end
            final -> final
          end
      end
    end
  end

  # Attempt to read timezone data from /etc/timezone
  defp read_timezone_data(@_ETC_TIMEZONE, date) do
    case File.exists?(@_ETC_TIMEZONE) do
      true ->
        etctz = File.read!(@_ETC_TIMEZONE)
        case etctz |> String.starts_with?("TZif2") do
          true ->
            case etctz |> File.read! |> parse_tzfile(date) do
              {:ok, tz}   -> {:ok, tz}
              {:error, m} -> raise m
            end
          false ->
            [no_hostdefs | _] = etctz |> String.split " ", [global: false, trim: true]
            [no_comments | _] = no_hostdefs |> String.split "#", [global: false, trim: true]
            {:ok, no_comments |> String.replace(" ", "_") |> String.strip(?\n)}
        end
      _ ->
        nil
    end
  end
  # If we've found a timezone, just keep on piping it through
  defp read_timezone_data({:ok, _} = result, _, _date), do: result
  # Otherwise, read the next fallback location
  defp read_timezone_data(_, file, _date) when file == @_ETC_SYS_CLOCK or file == @_ETC_CONF_CLOCK do
    case File.exists?(file) do
      true ->
        match = file
        |> File.stream!
        |> Stream.filter fn line -> Regex.match?(~r/(^ZONE=)|(^TIMEZONE=)/, line) end
        |> Enum.to_list
        |> List.first
        case match do
          m when m != nil ->
            [_, tz, _] = m |> String.split "\""
            {:ok, tz |> String.replace " ", "_"}
          _ ->
            nil
        end
      _ ->
        nil
    end
  end
  defp read_timezone_data(_, file, date) when file == @_ETC_LOCALTIME or file == @_USR_ETC_LOCALTIME do
    case File.exists?(file) do
      true ->
        case file |> File.read! |> parse_tzfile(date) do
          {:ok, tz}   -> {:ok, tz}
          {:error, m} -> raise m
        end
      _ ->
        nil
    end
  end

  # See http://linux.about.com/library/cmd/blcmdl5_tzfile.htm or
  # https://github.com/eggert/tz/blob/master/tzfile.h for details on the tzfile format
  # NOTE: These are defined as records, but I would've preferred to use `defrecordp` here to 
  # keep them private. The problem is that it is not possible to do the kind of manipulation
  # of records I'm doing in `parse_long`, etc. This is because unlike `defrecord`, `defrecordp`'s
  # functionality is based around macros and compile time knowledge. To reflect my desire to keep
  # these private, I've given them names in the `defrecordp` format, but they are still exposed
  # publically.
  defrecord :tzfile,
    # six big-endian 32-bit integers:
    #  number of UTC/local indicators
    utc_local_num: 0,
    #  number of standard/wall indicators
    std_wall_num: 0,
    #  number of leap seconds
    leap_num: 0,
    #  number of transition times
    time_num: 0,
    #  number of local time zones
    zone_num: 0,
    #  number of characters of time zone abbrev strings
    char_num: 0,
    # Transition times
    transitions: [],
    # Zone data,
    zones: [],
    # Leap second adjustments
    leaps: []
  defrecord :zone,
    offset:       0,
    is_dst?:      false,
    abbrev_index: 0,
    name:         "",
    is_std?:      false,
    is_utc?:      false
  defrecord :transition,
    when?:   0,
    zone:    nil
  defrecord :leap,
    when?:   0,
    adjust:  0

  @doc """
  Given a binary representing the data from a tzfile (not the source version),
  parses out the timezone for the provided reference date, or current UTC time
  if one wasn't provided.
  """
  @spec parse_tzfile(binary, DateTime.t | nil) :: {:ok, String.t} | {:error, term}

  def parse_tzfile(tzdata), do: parse_tzfile(tzdata, Date.universal())
  def parse_tzfile(tzdata, %DateTime{} = reference_date) do
    case tzdata do
      << ?T,?Z,?i,?f, rest :: binary >> ->
        # Trim reserved space
        << _ :: [bytes, size(16)], data :: binary >> = rest
        # Num of UTC/Local indicators
        {record, remaining} = {:tzfile[], data}
          |> parse_long(:utc_local_num)
          |> parse_long(:std_wall_num)
          |> parse_long(:leap_num)
          |> parse_long(:time_num)
          |> parse_long(:zone_num)
          |> parse_long(:char_num)
        # Extract transition times
        num_times = Range.new(1, record.time_num)
        {record, remaining} = Enum.reduce num_times, {record, remaining}, fn _, {r, d} ->
          {transition, rem} = {:transition[], d}
            |> parse_long(:when?)
          {r.update(transitions: r.transitions ++ [transition]), rem}
        end
        # Extract transition zone indices
        {record, remaining} = Enum.reduce num_times, {record, remaining}, fn i, {r, d} ->
          {txzone, rem} = d |> parse_uchar
          transition  = r.transitions |> Enum.at(i - 1)
          updated     = transition.update(zone: txzone)
          transitions = r.transitions |> List.replace_at(i - 1, updated)
          {r.update(transitions: transitions), rem}
        end
        # Extract zone data
        num_zones = Range.new(1, record.zone_num)
        {record, remaining} = Enum.reduce num_zones, {record, remaining}, fn _, {r, d} ->
          {zone, rem} = {:zone[], d}
            |> parse_long(:offset)
            |> parse_bool(:is_dst?)
            |> parse_uchar(:abbrev_index)
          {r.update(zones: r.zones ++ [zone]), rem}
        end
        # Extract zone abbreviations
        {record, remaining} = Enum.reduce num_zones, {record, remaining}, fn i, {r, d} ->
          {str, rem} = d |> parse_string(4)
          # Each abbreviation is a null terminated string, so trim the terminator
          <<abbrev :: [binary, size(3)], _ :: binary>> = str
          # Update the zone with it's extracted abbreviation
          zone    = r.zones |> Enum.at(i - 1)
          updated = zone.update(name: abbrev)
          zones   = r.zones |> List.replace_at(i - 1, updated)
          {r.update(zones: zones), rem}
        end
        # Extract leap adjustment pairs
        leap_pairs = Range.new(1, record.leap_num)
        # We may not have any valid pairs to look for, so check our range to
        # see if this extraction should just be a no-op
        noop?      = leap_pairs.last == 0
        {record, remaining} = Enum.reduce leap_pairs, {record, remaining}, fn _, {r, d} ->
          if noop? do
            {r, d}
          else
            {leap, rem} = {:leap[], d}
              |> parse_long(:when?)
              |> parse_long(:adjust)
            {r.update(leaps: r.leaps ++ [leap]), rem}
          end
        end
        # Extract standard/wall indicators
        num_stdwall = Range.new(1, record.std_wall_num)
        {record, remaining} = Enum.reduce num_stdwall, {record, remaining}, fn i, {r, d} ->
          {is_std?, rem} = d |> parse_bool
          # Update the zone with the extracted info
          zone    = r.zones |> Enum.at(i - 1)
          updated = zone.update(is_std?: is_std?)
          zones   = r.zones |> List.replace_at(i - 1, updated)
          {r.update(zones: zones), rem}
        end
        # Extract UTC/local indicators
        num_utclocal = Range.new(1, record.utc_local_num)
        {record, _} = Enum.reduce num_utclocal, {record, remaining}, fn i, {r, d} ->
          {is_utc?, rem} = d |> parse_bool
          # Update the zone with the extracted info
          zone    = r.zones |> Enum.at(i - 1)
          updated = zone.update(is_utc?: is_utc?)
          zones   = r.zones |> List.replace_at(i - 1, updated)
          {r.update(zones: zones), rem}
        end
        # Get the zone for the current time
        timestamp  = reference_date |> Date.to_secs
        current_tt = record.transitions
          |> Enum.sort(fn :transition[when?: utime1], :transition[when?: utime2] -> utime1 > utime2 end)
          |> Enum.reject(fn :transition[when?: unix_time] -> unix_time > timestamp end)
          |> List.first
        # We'll need these handy
        zones_available = record.zones
        # Attempt to get the proper timezone for the current transition we're in
        result = case current_tt do
          :transition[zone: zone_index] ->
            if zone_index <= Enum.count(record.zones) - 1 do
              # Sweet, we have a matching zone, we have our result!
              :zone[name: name] = zones_available |> Enum.fetch!(current_tt.zone)
              {:ok, name}
            else
              nil # Fallback to first standard-time zone
            end
          _ -> # Fallback to first standard-time zone
        end
        cond do
          # Success
          result != nil -> result
          # Damn, let's fallback to the first standard-time zone available
          true ->
            fallback = zones_available
              |> Enum.filter(fn zone -> zone.is_std? end)
              |> List.first
            case fallback do
              # Well, there are no standard-time zones then, just take the first zone available
              nil  -> 
                last_transition = record.transitions |> List.last
                :zone[name: name] = zones_available |> Enum.fetch!(last_transition.zone)
                {:ok, name}
              # Found a reasonable fallback zone, success?
              :zone[name: name] ->
                {:ok, name}
            end
        end
      false ->
        {:error, "Malformed time zone info!"}
    end
  end

  defp parse_long({record, data}, prop) do
    {val, rest} = data |> parse_long
    { record.update([{prop, val}]), rest }
  end
  defp parse_uchar({record, data}, prop) do
    {val, rest} = data |> parse_uchar
    { record.update([{prop, val}]), rest }
  end
  defp parse_bool({record, data}, prop) do
    {val, rest} = data |> parse_bool
    { record.update([{prop, val}]), rest }
  end
  defp parse_long(<<val :: 32, rest :: binary>>), do: { val, rest }
  defp parse_uchar(<<val :: 8, rest :: binary>>), do: { val, rest }
  defp parse_bool(<<val :: 8, rest :: binary>>),  do: { val == 1, rest }
  defp parse_string(data, length) do
    <<str :: [binary, size(length)], rest :: binary >> = data
    {str, rest}
  end
end