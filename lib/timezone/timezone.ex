defmodule Timex.Timezone do
  @moduledoc """
  Contains all the logic around conversion, manipulation,
  and comparison of time zones.
  """
  alias Timex.Date,           as: Date
  alias Timex.DateTime,       as: DateTime
  alias Timex.TimezoneInfo,   as: TimezoneInfo
  alias Timex.Timezone.Local, as: Local
  alias Timex.Timezone.Dst,   as: Dst

  @timezones_raw [
    # Automatically generated from the time zone database version 2013i for 2014-01-09.
    # Problems:
    # - Ignored Jun 29 in Rule Morocco.
    # - Ignored Jul 29 in Rule Morocco.
    # - Rounded Apr Sun>=23 to [4 :sun :apr] in Rule ChileAQ.
    # - Rounded Sep Sun>=2 to [1 :sun :sep] in Rule ChileAQ.
    # - Ignored Mar 22 in Rule Iran.
    # - Ignored Sep 22 in Rule Iran.
    # - Rounded Mar Fri>=23 to [4 :fri :mar] in Rule Zion.
    # - Rounded Sep Fri>=21 to [4 :fri :sep] in Rule Palestine.
    # - Rounded Oct Sun>=21 to [4 :sun :oct] in Rule Fiji.
    # - Rounded Jan Sun>=18 to [3 :sun :jan] in Rule Fiji.
    # - Rounded Apr Sun>=23 to [4 :sun :apr] in Rule Chile.
    # - Rounded Sep Sun>=2 to [1 :sun :sep] in Rule Chile.
    # - Discarded excess rules for Zone Africa/Casablanca.
    # - Discarded excess rules for Zone Africa/El_Aaiun.
    # - Moving rule to beginning of day for Zone America/Godthab.
    # - Moving rule to beginning of day for Zone America/Godthab.
    # - Moving rule to beginning of day for Zone Pacific/Easter.
    # - Moving rule to beginning of day for Zone Pacific/Easter.
    #
    {"Africa/Abidjan", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Accra", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Addis_Ababa", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Algiers", {"CET", "CET"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Asmara", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Asmera", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Bamako", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Bangui", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Banjul", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Bissau", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Blantyre", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Brazzaville", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Bujumbura", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Cairo", {"EET", "EET"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Casablanca", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Africa/Ceuta", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Africa/Conakry", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Dakar", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Dar_es_Salaam", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Djibouti", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Douala", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/El_Aaiun", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Africa/Freetown", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Gaborone", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Harare", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Johannesburg", {"SAST", "SAST"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Juba", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Kampala", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Khartoum", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Kigali", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Kinshasa", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Lagos", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Libreville", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Lome", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Luanda", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Lubumbashi", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Lusaka", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Malabo", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Maputo", {"CAT", "CAT"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Maseru", {"SAST", "SAST"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Mbabane", {"SAST", "SAST"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Mogadishu", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Monrovia", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Nairobi", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Ndjamena", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Niamey", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Nouakchott", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Ouagadougou", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Porto-Novo", {"WAT", "WAT"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Sao_Tome", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Timbuktu", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Tripoli", {"EET", "EET"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Tunis", {"CET", "CET"}, :undef, 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Africa/Windhoek", {"WAT", "WAT"}, {"WAST", "WAST"}, 60, 60, {1, :sun, :sep}, {2, 0}, {1, :sun, :apr}, {2, 0}}, 
    {"America/Adak", {"HAST", "HAST"}, {"HADT", "HADT"}, -600, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Anchorage", {"AKST", "AKST"}, {"AKDT", "AKDT"}, -540, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Anguilla", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Antigua", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Araguaina", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Buenos_Aires", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Catamarca", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/ComodRivadavia", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Cordoba", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Jujuy", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/La_Rioja", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Mendoza", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Rio_Gallegos", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Salta", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/San_Juan", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/San_Luis", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Tucuman", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Argentina/Ushuaia", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Aruba", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Asuncion", {"PYT", "PYT"}, {"PYST", "PYST"}, -240, 60, {1, :sun, :oct}, {0, 0}, {4, :sun, :mar}, {0, 0}}, 
    {"America/Atikokan", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Atka", {"HAST", "HAST"}, {"HADT", "HADT"}, -600, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Bahia", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Bahia_Banderas", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Barbados", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Belem", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Belize", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Blanc-Sablon", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Boa_Vista", {"AMT", "AMT"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Bogota", {"COT", "COT"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Boise", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Buenos_Aires", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Cambridge_Bay", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Campo_Grande", {"AMT", "AMT"}, {"AMST", "AMST"}, -240, 60, {3, :sun, :oct}, {0, 0}, {3, :sun, :feb}, {0, 0}}, 
    {"America/Cancun", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Caracas", {"VET", "VET"}, :undef, -270, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Catamarca", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Cayenne", {"GFT", "GFT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Cayman", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Chicago", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Chihuahua", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Coral_Harbour", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Cordoba", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Costa_Rica", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Creston", {"MST", "MST"}, :undef, -420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Cuiaba", {"AMT", "AMT"}, {"AMST", "AMST"}, -240, 60, {3, :sun, :oct}, {0, 0}, {3, :sun, :feb}, {0, 0}}, 
    {"America/Curacao", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Danmarkshavn", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Dawson", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Dawson_Creek", {"MST", "MST"}, :undef, -420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Denver", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Detroit", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Dominica", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Edmonton", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Eirunepe", {"ACT", "ACT"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/El_Salvador", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Ensenada", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Fort_Wayne", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Fortaleza", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Glace_Bay", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Godthab", {"WGT", "WGT"}, {"WGST", "WGST"}, -180, 60, {:last, :sun, :mar}, {0, 0}, {:last, :sun, :oct}, {0, 0}}, 
    {"America/Goose_Bay", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Grand_Turk", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Grenada", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Guadeloupe", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Guatemala", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Guayaquil", {"ECT", "ECT"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Guyana", {"GYT", "GYT"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Halifax", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Havana", {"CST", "CST"}, {"CDT", "CDT"}, -300, 60, {2, :sun, :mar}, {0, 0}, {1, :sun, :nov}, {1, 0}}, 
    {"America/Hermosillo", {"MST", "MST"}, :undef, -420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Indiana/Indianapolis", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Knox", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Marengo", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Petersburg", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Tell_City", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Vevay", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Vincennes", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indiana/Winamac", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Indianapolis", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Inuvik", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Iqaluit", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Jamaica", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Jujuy", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Juneau", {"AKST", "AKST"}, {"AKDT", "AKDT"}, -540, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Kentucky/Louisville", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Kentucky/Monticello", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Knox_IN", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Kralendijk", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/La_Paz", {"BOT", "BOT"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Lima", {"PET", "PET"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Los_Angeles", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Louisville", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Lower_Princes", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Maceio", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Managua", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Manaus", {"AMT", "AMT"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Marigot", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Martinique", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Matamoros", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Mazatlan", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Mendoza", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Menominee", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Merida", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Metlakatla", {"MeST", "MeST"}, :undef, -480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Mexico_City", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Miquelon", {"PMST", "PMST"}, {"PMDT", "PMDT"}, -180, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Moncton", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Monterrey", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Montevideo", {"UYT", "UYT"}, {"UYST", "UYST"}, -180, 60, {1, :sun, :oct}, {2, 0}, {2, :sun, :mar}, {2, 0}}, 
    {"America/Montreal", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Montserrat", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Nassau", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/New_York", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Nipigon", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Nome", {"AKST", "AKST"}, {"AKDT", "AKDT"}, -540, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Noronha", {"FNT", "FNT"}, :undef, -120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/North_Dakota/Beulah", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/North_Dakota/Center", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/North_Dakota/New_Salem", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Ojinaga", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Panama", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Pangnirtung", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Paramaribo", {"SRT", "SRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Phoenix", {"MST", "MST"}, :undef, -420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Port-au-Prince", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Port_of_Spain", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Porto_Acre", {"ACT", "ACT"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Porto_Velho", {"AMT", "AMT"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Puerto_Rico", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Rainy_River", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Rankin_Inlet", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Recife", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Regina", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Resolute", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Rio_Branco", {"ACT", "ACT"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Rosario", {"ART", "ART"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Santa_Isabel", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"America/Santarem", {"BRT", "BRT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Santiago", {"CLT", "CLT"}, {"CLST", "CLST"}, -240, 60, {1, :sun, :sep}, {0, 0}, {4, :sun, :apr}, {0, 0}}, 
    {"America/Santo_Domingo", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Sao_Paulo", {"BRT", "BRT"}, {"BRST", "BRST"}, -180, 60, {3, :sun, :oct}, {0, 0}, {3, :sun, :feb}, {0, 0}}, 
    {"America/Scoresbysund", {"EGT", "EGT"}, {"EGST", "EGST"}, -60, 60, {:last, :sun, :mar}, {0, 0}, {:last, :sun, :oct}, {1, 0}}, 
    {"America/Shiprock", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Sitka", {"AKST", "AKST"}, {"AKDT", "AKDT"}, -540, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/St_Barthelemy", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/St_Johns", {"NST", "NST"}, {"NDT", "NDT"}, -210, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/St_Kitts", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/St_Lucia", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/St_Thomas", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/St_Vincent", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Swift_Current", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Tegucigalpa", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Thule", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Thunder_Bay", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Tijuana", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Toronto", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Tortola", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Vancouver", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Virgin", {"AST", "AST"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"America/Whitehorse", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Winnipeg", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Yakutat", {"AKST", "AKST"}, {"AKDT", "AKDT"}, -540, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"America/Yellowknife", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Antarctica/Casey", {"WST", "WST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/Davis", {"DAVT", "DAVT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/DumontDUrville", {"DDUT", "DDUT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/Macquarie", {"MIST", "MIST"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/Mawson", {"MAWT", "MAWT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/McMurdo", {"NZST", "NZST"}, {"NZDT", "NZDT"}, 720, 60, {:last, :sun, :sep}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Antarctica/Palmer", {"CLT", "CLT"}, {"CLST", "CLST"}, -240, 60, {1, :sun, :sep}, {0, 0}, {4, :sun, :apr}, {0, 0}}, 
    {"Antarctica/Rothera", {"ROTT", "ROTT"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/South_Pole", {"NZST", "NZST"}, {"NZDT", "NZDT"}, 720, 60, {:last, :sun, :sep}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Antarctica/Syowa", {"SYOT", "SYOT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Antarctica/Vostok", {"VOST", "VOST"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Arctic/Longyearbyen", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Asia/Aden", {"AST", "AST"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Almaty", {"ALMT", "ALMT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Amman", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :thu, :mar}, {24, 0}, {:last, :fri, :oct}, {1, 0}}, 
    {"Asia/Anadyr", {"ANAT", "ANAT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Aqtau", {"AQTT", "AQTT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Aqtobe", {"AQTT", "AQTT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Ashgabat", {"TMT", "TMT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Ashkhabad", {"TMT", "TMT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Baghdad", {"AST", "AST"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Bahrain", {"AST", "AST"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Baku", {"AZT", "AZT"}, {"AZST", "AZST"}, 240, 60, {:last, :sun, :mar}, {4, 0}, {:last, :sun, :oct}, {5, 0}}, 
    {"Asia/Bangkok", {"ICT", "ICT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Beirut", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {0, 0}, {:last, :sun, :oct}, {0, 0}}, 
    {"Asia/Bishkek", {"KGT", "KGT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Brunei", {"BNT", "BNT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Calcutta", {"IST", "IST"}, :undef, 330, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Choibalsan", {"CHOT", "CHOT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Chongqing", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Chungking", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Colombo", {"IST", "IST"}, :undef, 330, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Dacca", {"BDT", "BDT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Damascus", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :fri, :mar}, {0, 0}, {:last, :fri, :oct}, {0, 0}}, 
    {"Asia/Dhaka", {"BDT", "BDT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Dili", {"TLT", "TLT"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Dubai", {"GST", "GST"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Dushanbe", {"TJT", "TJT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Gaza", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :thu, :mar}, {24, 0}, {4, :fri, :sep}, {0, 0}}, 
    {"Asia/Harbin", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Hebron", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :thu, :mar}, {24, 0}, {4, :fri, :sep}, {0, 0}}, 
    {"Asia/Ho_Chi_Minh", {"ICT", "ICT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Hong_Kong", {"HKT", "HKT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Hovd", {"HOVT", "HOVT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Irkutsk", {"IRKT", "IRKT"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Istanbul", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Asia/Jakarta", {"WIB", "WIB"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Jayapura", {"WIT", "WIT"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Jerusalem", {"IST", "IST"}, {"IDT", "IDT"}, 120, 60, {4, :fri, :mar}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Asia/Kabul", {"AFT", "AFT"}, :undef, 270, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kamchatka", {"PETT", "PETT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Karachi", {"PKT", "PKT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kashgar", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kathmandu", {"NPT", "NPT"}, :undef, 345, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Katmandu", {"NPT", "NPT"}, :undef, 345, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Khandyga", {"YAKT", "YAKT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kolkata", {"IST", "IST"}, :undef, 330, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Krasnoyarsk", {"KRAT", "KRAT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kuala_Lumpur", {"MYT", "MYT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kuching", {"MYT", "MYT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Kuwait", {"AST", "AST"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Macao", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Macau", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Magadan", {"MAGT", "MAGT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Makassar", {"WITA", "WITA"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Manila", {"PHT", "PHT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Muscat", {"GST", "GST"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Nicosia", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Asia/Novokuznetsk", {"NOVT", "NOVT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Novosibirsk", {"NOVT", "NOVT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Omsk", {"OMST", "OMST"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Oral", {"ORAT", "ORAT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Phnom_Penh", {"ICT", "ICT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Pontianak", {"WIB", "WIB"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Pyongyang", {"KST", "KST"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Qatar", {"AST", "AST"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Qyzylorda", {"QYZT", "QYZT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Rangoon", {"MMT", "MMT"}, :undef, 390, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Riyadh", {"AST", "AST"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Saigon", {"ICT", "ICT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Sakhalin", {"SAKT", "SAKT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Samarkand", {"UZT", "UZT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Seoul", {"KST", "KST"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Shanghai", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Singapore", {"SGT", "SGT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Taipei", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Tashkent", {"UZT", "UZT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Tbilisi", {"GET", "GET"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Tehran", {"IRST", "IRST"}, {"IRDT", "IRDT"}, 210, 60, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Tel_Aviv", {"IST", "IST"}, {"IDT", "IDT"}, 120, 60, {4, :fri, :mar}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Asia/Thimbu", {"BTT", "BTT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Thimphu", {"BTT", "BTT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Tokyo", {"JST", "JST"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Ujung_Pandang", {"WITA", "WITA"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Ulaanbaatar", {"ULAT", "ULAT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Ulan_Bator", {"ULAT", "ULAT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Urumqi", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Ust-Nera", {"VLAT", "VLAT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Vientiane", {"ICT", "ICT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Vladivostok", {"VLAT", "VLAT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Yakutsk", {"YAKT", "YAKT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Yekaterinburg", {"YEKT", "YEKT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Asia/Yerevan", {"AMT", "AMT"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Atlantic/Azores", {"AZOT", "AZOT"}, {"AZOST", "AZOST"}, -60, 60, {:last, :sun, :mar}, {0, 0}, {:last, :sun, :oct}, {1, 0}}, 
    {"Atlantic/Bermuda", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Atlantic/Canary", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Atlantic/Cape_Verde", {"CVT", "CVT"}, :undef, -60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Atlantic/Faeroe", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Atlantic/Faroe", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Atlantic/Jan_Mayen", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Atlantic/Madeira", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Atlantic/Reykjavik", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Atlantic/South_Georgia", {"GST", "GST"}, :undef, -120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Atlantic/St_Helena", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Atlantic/Stanley", {"FKST", "FKST"}, :undef, -180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/ACT", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Adelaide", {"CST", "CST"}, {"CST", "CST"}, 570, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Brisbane", {"EST", "EST"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Broken_Hill", {"CST", "CST"}, {"CST", "CST"}, 570, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Canberra", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Currie", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Darwin", {"CST", "CST"}, :undef, 570, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Eucla", {"CWST", "CWST"}, :undef, 525, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Hobart", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/LHI", {"LHST", "LHST"}, {"LHST", "LHST"}, 630, 30, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {2, 0}}, 
    {"Australia/Lindeman", {"EST", "EST"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Lord_Howe", {"LHST", "LHST"}, {"LHST", "LHST"}, 630, 30, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {2, 0}}, 
    {"Australia/Melbourne", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/NSW", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/North", {"CST", "CST"}, :undef, 570, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Perth", {"WST", "WST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Queensland", {"EST", "EST"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/South", {"CST", "CST"}, {"CST", "CST"}, 570, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Sydney", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Tasmania", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/Victoria", {"EST", "EST"}, {"EST", "EST"}, 600, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Australia/West", {"WST", "WST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Australia/Yancowinna", {"CST", "CST"}, {"CST", "CST"}, 570, 60, {1, :sun, :oct}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Brazil/Acre", {"ACT", "ACT"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Brazil/DeNoronha", {"FNT", "FNT"}, :undef, -120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Brazil/East", {"BRT", "BRT"}, {"BRST", "BRST"}, -180, 60, {3, :sun, :oct}, {0, 0}, {3, :sun, :feb}, {0, 0}}, 
    {"Brazil/West", {"AMT", "AMT"}, :undef, -240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"CET", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"CST6CDT", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/Atlantic", {"AST", "AST"}, {"ADT", "ADT"}, -240, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/Central", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/East-Saskatchewan", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Canada/Eastern", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/Mountain", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/Newfoundland", {"NST", "NST"}, {"NDT", "NDT"}, -210, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/Pacific", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Canada/Saskatchewan", {"CST", "CST"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Canada/Yukon", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Chile/Continental", {"CLT", "CLT"}, {"CLST", "CLST"}, -240, 60, {1, :sun, :sep}, {0, 0}, {4, :sun, :apr}, {0, 0}}, 
    {"Chile/EasterIsland", {"EAST", "EAST"}, {"EASST", "EASST"}, -360, 60, {1, :sun, :sep}, {0, 0}, {4, :sun, :apr}, {0, 0}}, 
    {"Cuba", {"CST", "CST"}, {"CDT", "CDT"}, -300, 60, {2, :sun, :mar}, {0, 0}, {1, :sun, :nov}, {1, 0}}, 
    {"EET", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"EST", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"EST5EDT", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Egypt", {"EET", "EET"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Eire", {"GMT", "GMT"}, {"IST", "IST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Etc/GMT", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-1", {"GMT-1", "GMT-1"}, :undef, -1 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-10", {"GMT-10", "GMT-10"}, :undef, -10 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-11", {"GMT-11", "GMT-11"}, :undef, -11 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-12", {"GMT-12", "GMT-12"}, :undef, -12 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-2", {"GMT-2", "GMT-2"}, :undef, -2 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-3", {"GMT-3", "GMT-3"}, :undef, -3 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-4", {"GMT-4", "GMT-4"}, :undef, -4 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-5", {"GMT-5", "GMT-5"}, :undef, -5 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-6", {"GMT-6", "GMT-6"}, :undef, -6 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-7", {"GMT-7", "GMT-7"}, :undef, -7 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-8", {"GMT-8", "GMT-8"}, :undef, -8 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-9", {"GMT-9", "GMT-9"}, :undef, -9 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT-0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+1", {"GMT+1", "GMT+1"}, :undef, 1 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+10", {"GMT+10", "GMT+10"}, :undef, 10 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+11", {"GMT+11", "GMT+11"}, :undef, 11 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+12", {"GMT+12", "GMT+12"}, :undef, 12 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+13", {"GMT+13", "GMT+13"}, :undef, 13 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+14", {"GMT+14", "GMT+14"}, :undef, 14 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+2", {"GMT+2", "GMT+2"}, :undef, 2 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+3", {"GMT+3", "GMT+3"}, :undef, 3 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+4", {"GMT+4", "GMT+4"}, :undef, 4 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+5", {"GMT+5", "GMT+5"}, :undef, 5 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+6", {"GMT+6", "GMT+6"}, :undef, 6 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+7", {"GMT+7", "GMT+7"}, :undef, 7 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+8", {"GMT+8", "GMT+8"}, :undef, 8 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT+9", {"GMT+9", "GMT+9"}, :undef, 9 * 60, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/GMT0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/Greenwich", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/UCT", {"UCT", "UCT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/UTC", {"UTC", "UTC"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/Universal", {"UTC", "UTC"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Etc/Zulu", {"UTC", "UTC"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Europe/Amsterdam", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Andorra", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Athens", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Belfast", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Belgrade", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Berlin", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Bratislava", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Brussels", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Bucharest", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Budapest", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Busingen", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Chisinau", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Copenhagen", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Dublin", {"GMT", "GMT"}, {"IST", "IST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Gibraltar", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Guernsey", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Helsinki", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Isle_of_Man", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Istanbul", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Jersey", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Kaliningrad", {"FET", "FET"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Europe/Kiev", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Lisbon", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Ljubljana", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/London", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Europe/Luxembourg", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Madrid", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Malta", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Mariehamn", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Minsk", {"FET", "FET"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Europe/Monaco", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Moscow", {"MSK", "MSK"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Europe/Nicosia", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Oslo", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Paris", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Podgorica", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Prague", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Riga", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Rome", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Samara", {"SAMT", "SAMT"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Europe/San_Marino", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Sarajevo", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Simferopol", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Skopje", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Sofia", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Stockholm", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Tallinn", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Tirane", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Tiraspol", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Uzhgorod", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Vaduz", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Vatican", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Vienna", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Vilnius", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Volgograd", {"VOLT", "VOLT"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Europe/Warsaw", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Zagreb", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Europe/Zaporozhye", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"Europe/Zurich", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"GB", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"GB-Eire", {"GMT", "GMT"}, {"BST", "BST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"GMT", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"GMT+0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"GMT-0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"GMT0", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Greenwich", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"HST", {"HST", "HST"}, :undef, -600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Hongkong", {"HKT", "HKT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Iceland", {"GMT", "GMT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Antananarivo", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Chagos", {"IOT", "IOT"}, :undef, 360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Christmas", {"CXT", "CXT"}, :undef, 420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Cocos", {"CCT", "CCT"}, :undef, 390, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Comoro", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Kerguelen", {"TFT", "TFT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Mahe", {"SCT", "SCT"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Maldives", {"MVT", "MVT"}, :undef, 300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Mauritius", {"MUT", "MUT"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Mayotte", {"EAT", "EAT"}, :undef, 180, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Indian/Reunion", {"RET", "RET"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Iran", {"IRST", "IRST"}, {"IRDT", "IRDT"}, 210, 60, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Israel", {"IST", "IST"}, {"IDT", "IDT"}, 120, 60, {4, :fri, :mar}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Jamaica", {"EST", "EST"}, :undef, -300, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Japan", {"JST", "JST"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Kwajalein", {"MHT", "MHT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Libya", {"EET", "EET"}, :undef, 120, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"MET", {"MET", "MET"}, {"MEST", "MEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"MST", {"MST", "MST"}, :undef, -420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"MST7MDT", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Mexico/BajaNorte", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Mexico/BajaSur", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Mexico/General", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {1, :sun, :apr}, {2, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"NZ", {"NZST", "NZST"}, {"NZDT", "NZDT"}, 720, 60, {:last, :sun, :sep}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"NZ-CHAT", {"CHAST", "CHAST"}, {"CHADT", "CHADT"}, 765, 60, {:last, :sun, :sep}, {2, 45}, {1, :sun, :apr}, {3, 45}}, 
    {"Navajo", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"PRC", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"PST8PDT", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"Pacific/Apia", {"WST", "WST"}, {"WSDT", "WSDT"}, 780, 1, {:last, :sun, :sep}, {3, 0}, {1, :sun, :apr}, {4, 0}}, 
    {"Pacific/Auckland", {"NZST", "NZST"}, {"NZDT", "NZDT"}, 720, 60, {:last, :sun, :sep}, {2, 0}, {1, :sun, :apr}, {3, 0}}, 
    {"Pacific/Chatham", {"CHAST", "CHAST"}, {"CHADT", "CHADT"}, 765, 60, {:last, :sun, :sep}, {2, 45}, {1, :sun, :apr}, {3, 45}}, 
    {"Pacific/Chuuk", {"CHUT", "CHUT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Easter", {"EAST", "EAST"}, {"EASST", "EASST"}, -360, 60, {1, :sun, :sep}, {0, 0}, {4, :sun, :apr}, {0, 0}}, 
    {"Pacific/Efate", {"VUT", "VUT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Enderbury", {"PHOT", "PHOT"}, :undef, 780, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Fakaofo", {"TKT", "TKT"}, :undef, 780, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Fiji", {"FJT", "FJT"}, {"FJST", "FJST"}, 720, 60, {4, :sun, :oct}, {2, 0}, {3, :sun, :jan}, {3, 0}}, 
    {"Pacific/Funafuti", {"TVT", "TVT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Galapagos", {"GALT", "GALT"}, :undef, -360, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Gambier", {"GAMT", "GAMT"}, :undef, -540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Guadalcanal", {"SBT", "SBT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Guam", {"ChST", "ChST"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Honolulu", {"HST", "HST"}, :undef, -600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Johnston", {"HST", "HST"}, :undef, -600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Kiritimati", {"LINT", "LINT"}, :undef, 840, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Kosrae", {"KOST", "KOST"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Kwajalein", {"MHT", "MHT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Majuro", {"MHT", "MHT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Marquesas", {"MART", "MART"}, :undef, -570, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Midway", {"SST", "SST"}, :undef, -660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Nauru", {"NRT", "NRT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Niue", {"NUT", "NUT"}, :undef, -660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Norfolk", {"NFT", "NFT"}, :undef, 690, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Noumea", {"NCT", "NCT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Pago_Pago", {"SST", "SST"}, :undef, -660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Palau", {"PWT", "PWT"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Pitcairn", {"PST", "PST"}, :undef, -480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Pohnpei", {"PONT", "PONT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Ponape", {"PONT", "PONT"}, :undef, 660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Port_Moresby", {"PGT", "PGT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Rarotonga", {"CKT", "CKT"}, :undef, -600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Saipan", {"ChST", "ChST"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Samoa", {"SST", "SST"}, :undef, -660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Tahiti", {"TAHT", "TAHT"}, :undef, -600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Tarawa", {"GILT", "GILT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Tongatapu", {"TOT", "TOT"}, :undef, 780, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Truk", {"CHUT", "CHUT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Wake", {"WAKT", "WAKT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Wallis", {"WFT", "WFT"}, :undef, 720, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Pacific/Yap", {"CHUT", "CHUT"}, :undef, 600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Poland", {"CET", "CET"}, {"CEST", "CEST"}, 60, 60, {:last, :sun, :mar}, {2, 0}, {:last, :sun, :oct}, {3, 0}}, 
    {"Portugal", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"ROC", {"CST", "CST"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"ROK", {"KST", "KST"}, :undef, 540, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Singapore", {"SGT", "SGT"}, :undef, 480, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Turkey", {"EET", "EET"}, {"EEST", "EEST"}, 120, 60, {:last, :sun, :mar}, {3, 0}, {:last, :sun, :oct}, {4, 0}}, 
    {"UCT", {"UCT", "UCT"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"US/Alaska", {"AKST", "AKST"}, {"AKDT", "AKDT"}, -540, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Aleutian", {"HAST", "HAST"}, {"HADT", "HADT"}, -600, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Arizona", {"MST", "MST"}, :undef, -420, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"US/Central", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/East-Indiana", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Eastern", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Hawaii", {"HST", "HST"}, :undef, -600, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"US/Indiana-Starke", {"CST", "CST"}, {"CDT", "CDT"}, -360, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Michigan", {"EST", "EST"}, {"EDT", "EDT"}, -300, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Mountain", {"MST", "MST"}, {"MDT", "MDT"}, -420, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Pacific", {"PST", "PST"}, {"PDT", "PDT"}, -480, 60, {2, :sun, :mar}, {2, 0}, {1, :sun, :nov}, {2, 0}}, 
    {"US/Samoa", {"SST", "SST"}, :undef, -660, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"UTC", {"UTC", "UTC"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"Universal", {"UTC", "UTC"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"W-SU", {"MSK", "MSK"}, :undef, 240, 0, :undef, {0, 0}, :undef, {0, 0}}, 
    {"WET", {"WET", "WET"}, {"WEST", "WEST"}, 0, 60, {:last, :sun, :mar}, {1, 0}, {:last, :sun, :oct}, {2, 0}}, 
    {"Zulu", {"UTC", "UTC"}, :undef, 0, 0, :undef, {0, 0}, :undef, {0, 0}}
  ]

  # Generate TimezoneInfo for each raw tuple
  @timezones @timezones_raw |> Enum.map fn data ->
    case data do
      {
        name, {std_abbr, std_name}, dst_names, 
        std_off, dst_off, dst_start_day, 
        dst_start_time, dst_end_day, dst_end_time
      } ->
        record = %TimezoneInfo{
          :full_name =>             name,
          :standard_abbreviation => std_abbr,
          :standard_name =>         std_name,
          :dst_abbreviation =>      std_abbr,
          :dst_name =>              std_name,
          :gmt_offset_std =>        std_off,
          :gmt_offset_dst =>        dst_off,
          :dst_start_day =>         dst_start_day,
          :dst_start_time =>        dst_start_time,
          :dst_end_day =>           dst_end_day,
          :dst_end_time =>          dst_end_time,
        }
        # Update DST names, if not :undef
        case dst_names do
            {dst_abbr, dst_name} ->
              %{record | :dst_abbreviation => dst_abbr, :dst_name => dst_name}
            :undef ->
              record
        end
      _ ->
        nil
    end
  end

  @doc """
  Get's the current local timezone configuration.
  You can provide a reference date to get the local timezone
  for a specific date, but the operation will not be cached
  lik getting the local timezone for the current date
  """
  def local() do
    case Process.get(:local_timezone) do
      nil ->
        tz = Local.lookup() |> get
        Process.put(:local_timezone, tz)
        tz
      tz ->
        tz
    end
  end
  def local(date), do: Local.lookup(date) |> get

  # Generate fast lookup functions for each timezone by their full name
  @timezones |> Enum.each fn tz ->
    def get(unquote(tz.full_name)), do: unquote(Macro.escape(tz))
  end
  # UTC is so common, we'll give it an extra shortcut, as well as handle common shortcuts
  def get(tz) when tz in ["Z", "UT", "GMT"], do: get(:utc)
  def get(:utc), do: get("UTC")
  def get(0),    do: get("UTC")
  # These are shorthand for specific time zones
  def get("A"),  do: get(-1)
  def get("M"),  do: get(-12)
  def get("N"),  do: get(+1)
  def get("Y"),  do: get(+12)
  # Allow querying by offset
  def get(offset) when is_number(offset) do
    if offset > 0 do
      get("Etc/GMT+#{offset}")
    else
      get("Etc/GMT#{offset}")
    end
  end
  def get(<<?+, offset :: binary>>) do 
    {num, _} = Integer.parse(offset)
    cond do
      num > 100 -> trunc(num/100) |> get
      true      -> get(num)
    end
  end
  def get(<<?-, offset :: binary>>) do
    {num, _} = Integer.parse(offset)
    cond do
      num > 100 -> get(trunc(num/100) * -1)
      true      -> get(num)
    end
  end
  @doc """
  Get the TimezoneInfo object corresponding to the given name.
  """
  # Fallback lookup by Standard/Daylight Savings time names/abbreviations
  def get(timezone) do
    @timezones |> Enum.find {:error, "No timezone found for: #{timezone}"}, fn info ->
      cond do
        timezone == info.standard_abbreviation -> true
        timezone == info.standard_name         -> true
        timezone == info.dst_abbreviation      -> true
        timezone == info.dst_name              -> true
        true                                   -> false
      end
    end
  end

  @doc """
  Convert a date to the given timezone.
  """
  @spec convert(date :: DateTime.t, tz :: TimezoneInfo.t) :: DateTime.t
  def convert(date, tz) do
    # Calculate the difference between `date`'s timezone, and the provided timezone
    difference = diff(date, tz)
    # Offset the provided date's time by the difference
    Date.shift(date, mins: difference) 
    |> Map.put(:timezone, tz) 
    |> Map.put(:ms, date.ms)
  end

  @doc """
  Determine what offset is required to convert a date into a target timezone
  """
  @spec diff(date :: DateTime.t, tz :: TimezoneInfo.t) :: integer
  def diff(%DateTime{:timezone => origin} = date, %TimezoneInfo{:gmt_offset_std => dest_std} = destination) do
    %TimezoneInfo{:gmt_offset_std => origin_std} = origin
    # Create a copy of the date in the new time zone so we can ask about DST
    target_date = %{date | :timezone => destination}
    # Determine DST status of origin and target
    origin_is_dst? = date        |> Dst.is_dst?
    target_is_dst? = target_date |> Dst.is_dst?
    # Get the difference, accounting for DST offsets
    cond do
      # Standard Time all the way
      !origin_is_dst? and !target_is_dst? -> dest_std - origin_std
      # Target is in DST
      !origin_is_dst? and  target_is_dst? -> coalesce(destination) - origin_std
      # Origin is in DST, target is not
       origin_is_dst? and !target_is_dst? -> dest_std - coalesce(origin)
      # DST all the way
      true -> coalesce(destination) - coalesce(origin)
    end
  end

  # Coalesce the standard time and daylight savings time offsets to get the proper DST offset
  defp coalesce(%TimezoneInfo{:gmt_offset_std => std, :gmt_offset_dst => dst}), do: std + dst

end
