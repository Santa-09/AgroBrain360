// PATH: lib/services/language_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_strings.dart';

class LangSvc extends ChangeNotifier {
  static final LangSvc _i = LangSvc._();
  factory LangSvc() => _i;
  LangSvc._();

  Map<String, String> _map = {};
  String _lang = '';

  static const Map<String, String> _fallback = {
    'appName': S.appName,
    'tagline': S.appTagline,
    'chooseLanguage': 'Choose Your Language',
    'languageSubtitle': "Select the language you're most comfortable with",
    'continueBtn': 'Continue',
    'welcomeBack': S.welcomeBack,
    'createAccount': S.signUp,
    'signIn': S.signIn,
    'signOut': 'Sign Out',
    'fullName': S.fullName,
    'phoneNumber': S.phone,
    'password': S.password,
    'email': 'Email',
    'forgotPassword': S.forgotPass,
    'newToApp': S.noAccount,
    'haveAccount': 'Already have an account? ',
    'signInSubtitle': 'Sign in to your farm dashboard',
    'joinFarmers': 'Join thousands of smart farmers',
    'offlineAI': 'Offline AI',
    'smartScan': 'Smart Scan',
    'fiveLangs': '5 Languages',
    'languageAppliesAppWide':
        'Language changes update the full app and all modules.',
    'languageSavedAfterSignOut':
        'Applied across all modules and kept after sign out.',
    'offlineSessionStarted':
        'Offline session started. Cloud sync will resume when internet is back.',
    'goodMorning': S.goodMorning,
    'goodAfternoon': S.goodAfternoon,
    'goodEvening': S.goodEvening,
    'home': 'Home',
    'scan': 'Scan',
    'history': 'History',
    'services': S.services,
    'profile': 'Profile',
    'cropDisease': S.cropDisease,
    'machinery': S.machinery,
    'livestock': S.livestock,
    'residue': S.residue,
    'farmHealth': S.farmHealth,
    'appTagline': 'Smart farming, rooted in every field',
    'preparingWorkspace': 'Preparing your farm workspace',
    'machineryModuleTitle': 'MACHINERY MODULE',
    'machineryModuleSubtitle':
        'Recommendation, maintenance, rental cost, and nearby machine rentals in one place.',
    'recommendation': 'Recommendation',
    'maintenance': 'Maintenance',
    'costCalculator': 'Cost Calculator',
    'nearbyRentals': 'Nearby Rentals',
    'machine': 'Machine',
    'machineType': 'Machine Type',
    'landSize': 'Land Size',
    'suggestMachine': 'Suggest Machine',
    'lastService': 'Last Service',
    'usage': 'Usage',
    'checkStatus': 'Check Status',
    'hours': 'Hours',
    'calculate': 'Calculate',
    'locationAutoInput': 'Location (Auto / Input)',
    'useMyLocation': 'Use My Location',
    'findRentals': 'Find Rentals',
    'ownerName': 'Owner Name',
    'pricePerHour': 'Price/hr',
    'contactButton': 'Contact Button',
    'distance': 'Distance',
    'ratePerHour': 'Rate/hr',
    'fuelEstimate': 'Fuel estimate',
    'operatorEstimate': 'Operator estimate',
    'total': 'Total',
    'locating': 'Locating...',
    'noRentalsFound': 'No rentals found for the selected machine.',
    'machineryLocationDefault': 'Set location to see nearest rentals',
    'machineryCropHint': 'Rice, wheat, maize, vegetables',
    'machineryLandHint': 'Area in acres',
    'machineryUsageHint': 'Hours since last service',
    'machineryHoursHint': 'Enter operating hours',
    'machineryLocationHint': 'Use current location or type city',
    'dateFormatHint': 'YYYY-MM-DD',
    'statusGood': 'Good',
    'statusUrgent': 'Urgent',
    'statusDueSoon': 'Due Soon',
    'statusCheckRecord': 'Check Record',
    'machineryEnableLocation':
        'Enable location services to fetch nearby rentals.',
    'machineryLocationPermission':
        'Location permission is needed for real-time rentals.',
    'machineryLiveLocationDetected': 'Live location detected',
    'machineryLocationFetchFailed': 'Unable to fetch current location.',
    'machineryManualLocationHelp':
        'Manual location not recognized. Try Bhubaneswar, Cuttack, Puri, Sambalpur, Berhampur, or Rourkela.',
    'machineryDialerFailed': 'Unable to open phone dialer.',
    'machineTractor': 'Tractor',
    'machinePowerTiller': 'Power Tiller',
    'machineSeedDrill': 'Seed Drill',
    'machineSprayer': 'Sprayer',
    'machineRotavator': 'Rotavator',
    'machineHarvester': 'Harvester',
    'machineWaterPump': 'Water Pump',
    'machineCultivator': 'Cultivator',
    'machineryReasonBalanced':
        'Balanced choice for tillage, haulage, and field preparation.',
    'machineryReasonRiceSmall':
        'Fits small wetland plots and reduces turning effort in rice fields.',
    'machineryReasonRiceLarge':
        'Larger rice acreage benefits from faster harvesting and lower labor dependence.',
    'machineryReasonCerealLarge':
        'Improves sowing speed and spacing consistency on medium to large plots.',
    'machineryReasonCerealSmall':
        'Efficient for seedbed prep and interculture on smaller cereal plots.',
    'machineryReasonVegetable':
        'Best for frequent protection sprays and nutrient application in intensive crops.',
    'machineryReasonSugarcane':
        'Useful for residue mixing and deep field preparation before ratoon or replanting.',
    'machineryTaskTillage': 'Primary tillage',
    'machineryTaskTransport': 'Transport',
    'machineryTaskFieldWork': 'General field work',
    'machineryTaskPuddling': 'Puddling',
    'machineryTaskInterCultivation': 'Inter-cultivation',
    'machineryTaskSmallPlot': 'Small-plot tillage',
    'machineryTaskHarvesting': 'Harvesting',
    'machineryTaskThreshing': 'Threshing support',
    'machineryTaskLaborSaving': 'Peak-season labor savings',
    'machineryTaskLineSowing': 'Line sowing',
    'machineryTaskSeedPlacement': 'Seed placement',
    'machineryTaskCoverageSpeed': 'Coverage speed',
    'machineryTaskWeeding': 'Weeding',
    'machineryTaskSoilLoosening': 'Soil loosening',
    'machineryTaskBedPreparation': 'Bed preparation',
    'machineryTaskPesticideSpray': 'Pesticide spray',
    'machineryTaskFoliarFeeding': 'Foliar feeding',
    'machineryTaskTargetedCare': 'Targeted crop care',
    'machineryTaskResidueMixing': 'Residue mixing',
    'machineryTaskSoilBreakup': 'Soil breakup',
    'machineryTaskFieldPreparation': 'Field preparation',
    'machineryStatusGoodNote':
        'Machine is within a safe maintenance window.',
    'machineryStatusUrgentNote':
        'Service immediately before next heavy operation to avoid breakdown risk.',
    'machineryStatusDueSoonNote':
        'Maintenance window is close. Plan service this week.',
    'machineryStatusCheckRecordNote':
        'Enter the last service date to assess maintenance risk accurately.',
    'confidence': 'Confidence',
    'resultLabel': 'Result',
    'severityLabel': 'Severity',
    'statusLabel': 'Status',
    'statusReady': 'Ready',
    'statusClear': 'Clear',
    'statusActNow': 'Act Now',
    'aboutThisCrop': 'About this crop',
    'aboutThisCondition': 'About this condition',
    'recommendedFertilizer': 'Recommended Fertilizer',
    'aiFieldAdvisory': 'AI Field Advisory',
    'symptomsIdentified': 'Symptoms Identified',
    'treatmentPlan': 'Treatment Plan',
    'costVsLossAnalysis': 'Cost vs Loss Analysis',
    'treatmentLabel': 'Treatment',
    'ifUntreated': 'If Untreated',
    'youSave': 'You Save',
    'detectAnotherCrop': 'Detect Another Crop',
    'scanAnotherCrop': 'Scan Another Crop',
    'cropDetectedBanner': 'CROP DETECTED',
    'healthyBanner': 'HEALTHY',
    'diseaseDetectedBanner': 'DISEASE DETECTED',
    'unknownLabel': 'Unknown',
    'livestockDiagnosisTitle': 'Livestock Diagnosis',
    'selectAnimal': 'Select Animal',
    'animalPhotoOptional': 'Animal photo (optional)',
    'tapToAddPhoto': 'Tap to add photo',
    'describeSymptoms': 'Describe Symptoms',
    'livestockSymptomsHint': 'Describe visible symptoms, behavior changes, appetite loss, fever, wounds, or breathing issues',
    'diagnoseNow': 'Diagnose Now',
    'diagnosingWithAI': 'Diagnosing with AI...',
    'voice': 'Voice',
    'aiVoice': 'AI Voice',
    'voiceProcessed': 'AI voice response ready',
    'voiceFailed': 'AI voice request failed',
    'recordingAiVoice': 'Recording for AI voice... tap Stop when finished.',
    'stop': 'Stop',
    'listeningSpeakClearly': 'Listening... speak clearly',
    'pleaseDescribeSymptoms': 'Please describe symptoms',
    'diagnosisFailed': 'Diagnosis failed',
    'residueAnalysisTitle': 'Residue Analysis',
    'residueType': 'Residue Type',
    'moistureLevel': 'Moisture Level',
    'voiceDetailsOptional': 'Voice details (optional)',
    'voiceNotes': 'Voice notes',
    'voiceNotesHintResidue': 'Describe crop residue type, moisture, and any extra field notes',
    'betterSuggestion': 'Ask AI for Better Suggestion',
    'aiHelpCenter': 'AI Help Center',
    'aiHelpWelcome': 'I can explain this case in simple steps. Ask about the problem, treatment, prevention, or next action.',
    'aiHelpHint': 'Ask about problem, treatment, prevention, or next step',
    'residueListening': 'Listening... mention residue type and moisture clearly',
    'calculateIncome': 'Calculate Income Options',
    'residuePhotoTitle': 'Tap to photograph the crop residue',
    'residuePhotoSub': 'Capture a clear photo for income and reuse guidance',
    'residueTip': 'Stop burning stubble. Convert residue into compost, fodder, or briquettes for extra income.',
    'pleaseTakePhotoFirst': 'Please take a photo first',
    'farmInput': 'Farm Health Input',
    'calculateFHI': 'Calculate Farm Health Score',
    'cropCondition': 'Crop',
    'soilHealth': 'Soil',
    'waterAccess': 'Water',
    'livestockStatus': 'Livestock',
    'machineryStatus': 'Machinery',
    'rateEachCategory': 'Rate each category to estimate the overall farm health score.',
    'scanHistory': 'Scan History',
    'clearAll': 'Clear All',
    'allLabel': 'All',
    'noHistory': 'No scans yet',
    'noHistorySub': 'Your scan history will appear here',
    'forgotPasswordTitle': 'Forgot Password',
    'sendOtp': 'Send OTP',
    'nearbyServices': 'Nearby Services',
    'offlineCropDetectionResult':
        'Offline crop detection - connect for enhanced cloud results',
    'offlineDiagnosisResult':
        'Offline diagnosis - connect for enhanced cloud results',
    'recaptureDiseaseInput':
        'Please recapture the image. This does not match a detectable disease input.',
    'arRepairAssist': 'AR Repair Assist',
    'machineryRepairSub':
        'Capture the faulty part and open a guided overlay with tools and step-by-step repair help.',
    'issueType': 'Issue Type',
    'openArGuide': 'Open AR Guide',
    'machineryRepairNeedsPhoto':
        'Capture a machine-part photo before opening repair assist.',
    'guidedRepairSteps': 'Guided repair steps',
    'repairToolsChecklist': 'Tools checklist',
    'stepLabel': 'Step',
    'overlayTarget': 'Overlay target',
    'machineryArSafetyNote':
        'Turn off the engine, remove the key, and let hot parts cool before attempting any repair.',
    'issueEngineNoise': 'Engine Noise',
    'issueOilLeak': 'Oil Leak',
    'issueOverheating': 'Overheating',
    'issueLowSprayPressure': 'Low Spray Pressure',
    'issueBatteryIssue': 'Battery Issue',
    'issueLooseBelt': 'Loose Belt',
    'overlayEngineNoise':
        'Align this box over the engine bay or drive section where the sound is strongest.',
    'overlayOilLeak':
        'Match the highlighted area with hoses, seals, and the lower engine casing.',
    'overlayOverheating':
        'Align this box over the radiator, coolant pipe, or air vents.',
    'overlaySprayer':
        'Align on the nozzle line, filter cup, or pump head to inspect spray blockage.',
    'overlayBattery':
        'Align on the battery terminals and cable clamps to inspect corrosion or loose contact.',
    'overlayBelt':
        'Align on the pulley-belt path to inspect cracks, slack, or misalignment.',
    'toolSpanner': 'Spanner set',
    'toolTorch': 'Torch',
    'toolCleanCloth': 'Clean cloth',
    'toolGloves': 'Gloves',
    'toolBrush': 'Soft brush',
    'toolCoolant': 'Coolant / water',
    'toolNeedle': 'Cleaning pin',
    'toolBucket': 'Water bucket',
    'toolWrench': 'Small wrench',
    'toolTester': 'Voltage tester',
    'repairEngineNoiseStep1':
        'Switch off the machine and inspect visible bolts, covers, and mountings in the highlighted zone.',
    'repairEngineNoiseStep2':
        'Check for loose guards, leaking pipes, or belt rubbing near the sound source.',
    'repairEngineNoiseStep3':
        'Tighten loose fittings and avoid heavy use until abnormal noise is resolved.',
    'repairOilLeakStep1':
        'Wipe the suspected area clean so the fresh leak point becomes visible.',
    'repairOilLeakStep2':
        'Check hose joints, filter mount, and drain plug for loose fittings.',
    'repairOilLeakStep3':
        'Tighten the loose connection gently and replace damaged seal or hose before reuse.',
    'repairOverheatStep1':
        'Let the machine cool fully before touching the radiator area.',
    'repairOverheatStep2':
        'Remove dust from fins or vents and inspect coolant or water level.',
    'repairOverheatStep3':
        'Check belt tension and restart only after airflow and coolant are restored.',
    'repairSprayStep1':
        'Flush the tank line and remove the nozzle cap carefully.',
    'repairSprayStep2':
        'Clean the nozzle and inline filter without widening the nozzle hole.',
    'repairSprayStep3':
        'Prime the pump again and test with clean water before spraying chemical mix.',
    'repairBatteryStep1':
        'Switch the machine off and inspect terminals for white or green corrosion.',
    'repairBatteryStep2':
        'Clean the terminals, tighten cable clamps, and check the fuse link.',
    'repairBatteryStep3':
        'If cranking is still weak, recharge or replace the battery before field use.',
    'repairBeltStep1':
        'Inspect the belt for cracks, glazing, or excessive looseness.',
    'repairBeltStep2':
        'Adjust pulley tension gradually until the belt deflects only slightly by hand.',
    'repairBeltStep3':
        'Replace the belt if edges are frayed or if slippage continues after adjustment.',
  };

  static const Map<String, Map<String, String>> _localizedFallback = {
    'hi': {
      'machineryModuleTitle': 'मशीनरी मॉड्यूल',
      'machineryModuleSubtitle': 'सिफारिश, मेंटेनेंस, किराया लागत और नज़दीकी मशीन रेंटल एक ही जगह।',
      'recommendation': 'सिफारिश',
      'maintenance': 'मेंटेनेंस',
      'costCalculator': 'लागत कैलकुलेटर',
      'nearbyRentals': 'नज़दीकी रेंटल',
      'machine': 'मशीन',
      'machineType': 'मशीन प्रकार',
      'cropLabel': 'फसल',
      'landSize': 'भूमि आकार',
      'suggestMachine': 'मशीन सुझाएँ',
      'lastService': 'अंतिम सर्विस',
      'usage': 'उपयोग',
      'checkStatus': 'स्थिति जाँचें',
      'hours': 'घंटे',
      'calculate': 'गणना करें',
      'locationAutoInput': 'स्थान (ऑटो / इनपुट)',
      'useMyLocation': 'मेरी लोकेशन उपयोग करें',
      'findRentals': 'रेंटल खोजें',
      'ownerName': 'मालिक का नाम',
      'pricePerHour': 'मूल्य/घंटा',
      'contactButton': 'संपर्क करें',
      'distance': 'दूरी',
      'ratePerHour': 'दर/घंटा',
      'fuelEstimate': 'ईंधन अनुमान',
      'operatorEstimate': 'ऑपरेटर अनुमान',
      'total': 'कुल',
      'locating': 'लोकेशन मिल रही है...',
      'noRentalsFound': 'चुनी गई मशीन के लिए कोई रेंटल नहीं मिला।',
      'confidence': 'विश्वास',
      'resultLabel': 'परिणाम',
      'severityLabel': 'गंभीरता',
      'statusLabel': 'स्थिति',
      'aboutThisCrop': 'इस फसल के बारे में',
      'aboutThisCondition': 'इस स्थिति के बारे में',
      'recommendedFertilizer': 'सुझाया गया उर्वरक',
      'aiFieldAdvisory': 'एआई फील्ड सलाह',
      'symptomsIdentified': 'पहचाने गए लक्षण',
      'treatmentPlan': 'उपचार योजना',
      'costVsLossAnalysis': 'लागत बनाम नुकसान विश्लेषण',
      'treatmentLabel': 'उपचार',
      'ifUntreated': 'यदि उपचार न करें',
      'youSave': 'आपकी बचत',
      'detectAnotherCrop': 'एक और फसल पहचानें',
      'scanAnotherCrop': 'एक और फसल स्कैन करें',
    },
    'od': {
      'machineryModuleTitle': 'ଯନ୍ତ୍ର ବିଭାଗ',
      'machineryModuleSubtitle': 'ସୁପାରିଶ, ମେଣ୍ଟେନାନ୍ସ, ଭାଡା ଖର୍ଚ୍ଚ ଓ ନିକଟସ୍ଥ ଭାଡା ଯନ୍ତ୍ର ଏକଠି।',
      'recommendation': 'ସୁପାରିଶ',
      'maintenance': 'ରକ୍ଷାଣାବେକ୍ଷଣ',
      'costCalculator': 'ଖର୍ଚ୍ଚ ଗଣନା',
      'nearbyRentals': 'ନିକଟସ୍ଥ ଭାଡା',
      'machine': 'ଯନ୍ତ୍ର',
      'machineType': 'ଯନ୍ତ୍ର ପ୍ରକାର',
      'cropLabel': 'ଫସଲ',
      'landSize': 'ଜମି ଆକାର',
      'suggestMachine': 'ଯନ୍ତ୍ର ସୁପାରିଶ କରନ୍ତୁ',
      'lastService': 'ଶେଷ ସର୍ଭିସ',
      'usage': 'ବ୍ୟବହାର',
      'checkStatus': 'ସ୍ଥିତି ଯାଞ୍ଚ',
      'hours': 'ଘଣ୍ଟା',
      'calculate': 'ଗଣନା କରନ୍ତୁ',
      'locationAutoInput': 'ଅବସ୍ଥାନ (ଅଟୋ / ଇନପୁଟ)',
      'useMyLocation': 'ମୋ ଅବସ୍ଥାନ ବ୍ୟବହାର କରନ୍ତୁ',
      'findRentals': 'ଭାଡା ଖୋଜନ୍ତୁ',
      'ownerName': 'ମାଲିକଙ୍କ ନାମ',
      'pricePerHour': 'ମୂଲ୍ୟ/ଘଣ୍ଟା',
      'contactButton': 'ଯୋଗାଯୋଗ କରନ୍ତୁ',
      'distance': 'ଦୂରତା',
      'ratePerHour': 'ଦର/ଘଣ୍ଟା',
      'fuelEstimate': 'ଇନ୍ଧନ ଅନୁମାନ',
      'operatorEstimate': 'ଚାଳକ ଅନୁମାନ',
      'total': 'ମୋଟ',
      'confidence': 'ଭରସା',
      'resultLabel': 'ଫଳାଫଳ',
      'severityLabel': 'ତୀବ୍ରତା',
      'statusLabel': 'ସ୍ଥିତି',
      'recommendedFertilizer': 'ସୁପାରିଶିତ ସାର',
      'treatmentPlan': 'ଚିକିତ୍ସା ଯୋଜନା',
      'detectAnotherCrop': 'ଆଉ ଗୋଟିଏ ଫସଲ ଚିହ୍ନଟ କରନ୍ତୁ',
      'scanAnotherCrop': 'ଆଉ ଗୋଟିଏ ଫସଲ ସ୍କାନ କରନ୍ତୁ',
    },
    'ta': {
      'machineryModuleTitle': 'இயந்திர பகுதி',
      'machineryModuleSubtitle': 'பரிந்துரை, பராமரிப்பு, வாடகை செலவு மற்றும் அருகிலுள்ள இயந்திர வாடகை ஒரே இடத்தில்.',
      'recommendation': 'பரிந்துரை',
      'maintenance': 'பராமரிப்பு',
      'costCalculator': 'செலவு கணக்கீடு',
      'nearbyRentals': 'அருகிலுள்ள வாடகைகள்',
      'machine': 'இயந்திரம்',
      'machineType': 'இயந்திர வகை',
      'cropLabel': 'பயிர்',
      'landSize': 'நில அளவு',
      'suggestMachine': 'இயந்திரம் பரிந்துரைக்கவும்',
      'lastService': 'கடைசி சேவை',
      'usage': 'பயன்பாடு',
      'checkStatus': 'நிலையை சரிபார்',
      'hours': 'மணிநேரம்',
      'calculate': 'கணக்கிடு',
      'locationAutoInput': 'இடம் (ஆட்டோ / உள்ளீடு)',
      'useMyLocation': 'என் இடத்தை பயன்படுத்து',
      'findRentals': 'வாடகைகளை கண்டுபிடி',
      'ownerName': 'உரிமையாளர் பெயர்',
      'pricePerHour': 'விலை/மணி',
      'contactButton': 'தொடர்பு கொள்ள',
      'distance': 'தூரம்',
      'confidence': 'நம்பிக்கை',
      'resultLabel': 'முடிவு',
      'severityLabel': 'தீவிரம்',
      'statusLabel': 'நிலை',
      'recommendedFertilizer': 'பரிந்துரைக்கப்பட்ட உரம்',
      'treatmentPlan': 'சிகிச்சை திட்டம்',
      'detectAnotherCrop': 'மற்றொரு பயிரை கண்டறி',
      'scanAnotherCrop': 'மற்றொரு பயிரை ஸ்கேன் செய்',
    },
    'te': {
      'machineryModuleTitle': 'యంత్ర విభాగం',
      'machineryModuleSubtitle': 'సిఫార్సు, నిర్వహణ, అద్దె ఖర్చు మరియు సమీప యంత్ర అద్దెలు ఒకే చోట.',
      'recommendation': 'సిఫార్సు',
      'maintenance': 'నిర్వహణ',
      'costCalculator': 'ఖర్చు లెక్కింపు',
      'nearbyRentals': 'సమీప అద్దెలు',
      'machine': 'యంత్రం',
      'machineType': 'యంత్ర రకం',
      'cropLabel': 'పంట',
      'landSize': 'భూమి పరిమాణం',
      'suggestMachine': 'యంత్రాన్ని సూచించండి',
      'lastService': 'చివరి సేవ',
      'usage': 'వినియోగం',
      'checkStatus': 'స్థితి చూడండి',
      'hours': 'గంటలు',
      'calculate': 'లెక్కించు',
      'locationAutoInput': 'స్థానం (ఆటో / ఇన్‌పుట్)',
      'useMyLocation': 'నా స్థానం ఉపయోగించు',
      'findRentals': 'అద్దెలు కనుగొను',
      'ownerName': 'యజమాని పేరు',
      'pricePerHour': 'ధర/గంట',
      'contactButton': 'సంప్రదించండి',
      'distance': 'దూరం',
      'confidence': 'నమ్మకం',
      'resultLabel': 'ఫలితం',
      'severityLabel': 'తీవ్రత',
      'statusLabel': 'స్థితి',
      'recommendedFertilizer': 'సిఫార్సు చేసిన ఎరువు',
      'treatmentPlan': 'చికిత్స ప్రణాళిక',
      'detectAnotherCrop': 'మరో పంటను గుర్తించండి',
      'scanAnotherCrop': 'మరో పంటను స్కాన్ చేయండి',
    },
  };

  String get lang => _lang.isEmpty ? 'en' : _lang;

  bool get needsPicker => false;

  /// Supported languages
  static const Map<String, String> supported = {
    'en': 'English',
    'hi': 'Hindi',
    'od': 'Odia',
    'ta': 'Tamil',
    'te': 'Telugu',
  };

  /// Native language names
  static const Map<String, String> nativeNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'od': 'ଓଡ଼ିଆ',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
  };

  /// Flag emojis
  static const Map<String, String> flags = {
    'en': '🇬🇧',
    'hi': '🇮🇳',
    'od': '🇮🇳',
    'ta': '🇮🇳',
    'te': '🇮🇳',
  };

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _lang = p.getString('lang') ?? 'en';
    await _load(_lang);
  }

  /// Used for language change
  Future<void> set(String code) async {
    _lang = code;

    final p = await SharedPreferences.getInstance();
    await p.setString('lang', code);

    await _load(code);

    notifyListeners();
  }

  /// Used on first launch language picker
  Future<void> setFirst(String code) async {
    await set(code);
  }

  Future<void> _load(String code) async {
    try {
      final raw = await rootBundle.loadString('assets/languages/$code.json');

      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      _map = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _map = {};
    }
  }

  String t(String key) =>
      _map[key] ?? _localizedFallback[lang]?[key] ?? _fallback[key] ?? key;

  String greeting() {
    final h = DateTime.now().hour;

    if (h < 12) return t('goodMorning');
    if (h < 17) return t('goodAfternoon');

    return t('goodEvening');
  }
}
