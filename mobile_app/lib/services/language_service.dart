// PATH: lib/services/language_service.dart
import 'dart:convert' show jsonDecode, latin1, utf8;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_strings.dart';

class LangSvc extends ChangeNotifier {
  static final LangSvc _i = LangSvc._();
  factory LangSvc() => _i;
  LangSvc._();

  Map<String, String> _map = {};
  Map<String, String> _englishMap = {};
  Map<String, String> _selectedMap = {};
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
    'dashboardMorningLine':
        'A fresh start for field checks, watering plans, and early decisions.',
    'dashboardAfternoonLine':
        'Keep an eye on heat, crop stress, and pending farm tasks this afternoon.',
    'dashboardEveningLine':
        'Wrap up today with quick checks on crops, livestock, and tomorrow\'s plan.',
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
    'voiceUnavailable': 'Voice input is unavailable right now',
    'aiVoice': 'AI Voice',
    'voiceProcessed': 'AI voice response ready',
    'voiceFailed': 'AI voice request failed',
    'speakAdvice': 'Speak Advice',
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
    'projectedEarnings': 'Projected earnings',
    'residuePhotoTitle': 'Tap to photograph the crop residue',
    'residuePhotoSub': 'Capture a clear photo for income and reuse guidance',
    'residueTip': 'Stop burning stubble. Convert residue into compost, fodder, or briquettes for extra income.',
    'pleaseTakePhotoFirst': 'Please take a photo first',
    'farmInput': 'Farm Health Input',
    'calculateFHI': 'Calculate Farm Health Score',
    'cropCondition': 'Crop',
    'plantName': 'Plant name',
    'selectPlantName': 'Select the plant name',
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
    'animalCow': 'Cow',
    'animalBuffalo': 'Buffalo',
    'animalGoat': 'Goat',
    'animalSheep': 'Sheep',
    'animalPig': 'Pig',
    'animalChicken': 'Chicken',
    'animalHorse': 'Horse',
    'animalFish': 'Fish',
    'recommendedLabel': 'Recommended',
    'analyzedLabel': 'Analyzed',
    'sourceLabel': 'Source',
    'offlineLabel': 'Offline',
    'cloudLabel': 'Cloud',
    'topRecommendations': 'Top Recommendations',
    'recommendAgain': 'Recommend Again',
    'specialty': 'Specialty',
    'address': 'Address',
    'phone': 'Phone',
    'openNow': 'Open Now',
    'callNow': 'Call Now',
    'chatOnWhatsApp': 'Chat on WhatsApp',
    'getDirections': 'Get Directions',
    'requestTimedOut': 'Request timed out. Please try again.',
    'somethingWentWrong': 'Something went wrong. Please try again.',
    'justNow': 'Just now',
    'minutesAgo': '{value}m ago',
    'hoursAgo': '{value}h ago',
    'daysAgo': '{value}d ago',
  };

  static const Map<String, Map<String, String>> _extraLocalizedFallback = {
    'hi': {
      'plantName': 'पौधे का नाम',
      'selectPlantName': 'पौधे का नाम चुनें',
      'dashboardMorningLine':
          'खेत की जांच, सिंचाई योजना और सुबह के फैसलों के लिए यह एक ताज़ा शुरुआत है।',
      'dashboardAfternoonLine':
          'इस दोपहर गर्मी, फसल तनाव और बाकी खेत के कामों पर नज़र रखें।',
      'dashboardEveningLine':
          'आज की फसल, पशुधन और कल की योजना की शाम को जल्दी समीक्षा करें।',
      'animalCow': 'गाय',
      'animalBuffalo': 'भैंस',
      'animalGoat': 'बकरी',
      'animalSheep': 'भेड़',
      'animalPig': 'सुअर',
      'animalChicken': 'मुर्गी',
      'animalHorse': 'घोड़ा',
      'animalFish': 'मछली',
      'recommendedLabel': 'सिफारिश',
      'analyzedLabel': 'विश्लेषित',
      'sourceLabel': 'स्रोत',
      'offlineLabel': 'ऑफलाइन',
      'cloudLabel': 'क्लाउड',
      'topRecommendations': 'शीर्ष सिफारिशें',
      'recommendAgain': 'फिर सिफारिश करें',
      'specialty': 'विशेषता',
      'address': 'पता',
      'phone': 'फोन',
      'openNow': 'अभी खुला',
      'callNow': 'अभी कॉल करें',
      'chatOnWhatsApp': 'व्हाट्सऐप पर चैट',
      'getDirections': 'दिशा देखें',
      'requestTimedOut': 'अनुरोध का समय समाप्त हो गया। फिर प्रयास करें।',
      'somethingWentWrong': 'कुछ गलत हुआ। फिर प्रयास करें।',
      'justNow': 'अभी',
      'minutesAgo': '{value} मिनट पहले',
      'hoursAgo': '{value} घंटे पहले',
      'daysAgo': '{value} दिन पहले',
    },
    'od': {
      'plantName': 'ଗଛର ନାମ',
      'selectPlantName': 'ଗଛର ନାମ ବାଛନ୍ତୁ',
      'dashboardMorningLine':
          'କ୍ଷେତ ଯାଞ୍ଚ, ପାଣି ଯୋଜନା ଏବଂ ସକାଳର ନିଷ୍ପତ୍ତି ପାଇଁ ଏହା ଭଲ ଆରମ୍ଭ।',
      'dashboardAfternoonLine':
          'ଏହି ଦୁପରେ ଗରମ, ଫସଲ ଚାପ ଏବଂ ବାକି କାମ ଉପରେ ନଜର ରଖନ୍ତୁ।',
      'dashboardEveningLine':
          'ଆଜିର ଫସଲ, ପଶୁପାଳନ ଏବଂ କାଲିର ଯୋଜନାକୁ ସନ୍ଧ୍ୟାରେ ଥରେ ଯାଞ୍ଚ କରନ୍ତୁ।',
      'animalCow': 'ଗାଈ',
      'animalBuffalo': 'ମହିଷ',
      'animalGoat': 'ଛେଳି',
      'animalSheep': 'ଭେଡ଼ା',
      'animalPig': 'ସୁଆର',
      'animalChicken': 'କୁକୁଡ଼ି',
      'animalHorse': 'ଘୋଡ଼ା',
      'animalFish': 'ମାଛ',
      'recommendedLabel': 'ସୁପାରିଶ',
      'analyzedLabel': 'ବିଶ୍ଳେଷିତ',
      'sourceLabel': 'ଉତ୍ସ',
      'offlineLabel': 'ଅଫଲାଇନ',
      'cloudLabel': 'କ୍ଲାଉଡ୍',
      'topRecommendations': 'ଶୀର୍ଷ ସୁପାରିଶ',
      'recommendAgain': 'ପୁନି ସୁପାରିଶ କରନ୍ତୁ',
      'specialty': 'ବିଶେଷତା',
      'address': 'ଠିକଣା',
      'phone': 'ଫୋନ',
      'openNow': 'ଏବେ ଖୋଲା',
      'callNow': 'ଏବେ କଲ୍ କରନ୍ତୁ',
      'chatOnWhatsApp': 'WhatsApp ରେ ଚ୍ୟାଟ',
      'getDirections': 'ପଥ ଦେଖନ୍ତୁ',
      'requestTimedOut': 'ଅନୁରୋଧର ସମୟ ସମାପ୍ତ ହୋଇଗଲା। ପୁନି ଚେଷ୍ଟା କରନ୍ତୁ।',
      'somethingWentWrong': 'କିଛି ଭୁଲ୍ ହୋଇଛି। ପୁନି ଚେଷ୍ଟା କରନ୍ତୁ।',
      'justNow': 'ଏମିତିକି',
      'minutesAgo': '{value}ମି ପୂର୍ବରୁ',
      'hoursAgo': '{value}ଘ ପୂର୍ବରୁ',
      'daysAgo': '{value}ଦିନ ପୂର୍ବରୁ',
    },
    'ta': {
      'plantName': 'தாவரத்தின் பெயர்',
      'selectPlantName': 'தாவரத்தின் பெயரைத் தேர்ந்தெடுக்கவும்',
      'dashboardMorningLine':
          'வயல் பரிசோதனை, நீர்ப்பாசன திட்டம் மற்றும் காலையிலான முடிவுகளுக்கான புதிய தொடக்கம் இது.',
      'dashboardAfternoonLine':
          'இந்த மதியத்தில் வெப்பம், பயிர் அழுத்தம் மற்றும் மீதமுள்ள பண்ணை பணிகளை கவனியுங்கள்.',
      'dashboardEveningLine':
          'இன்றைய பயிர், கால்நடை மற்றும் நாளைய திட்டத்தை மாலையில் ஒருமுறை பாருங்கள்.',
      'animalCow': 'பசு',
      'animalBuffalo': 'எருமை',
      'animalGoat': 'ஆடு',
      'animalSheep': 'செம்மறியாடு',
      'animalPig': 'பன்றி',
      'animalChicken': 'கோழி',
      'animalHorse': 'குதிரை',
      'animalFish': 'மீன்',
      'recommendedLabel': 'பரிந்துரை',
      'analyzedLabel': 'பகுப்பாய்வு முடிந்தது',
      'sourceLabel': 'மூலம்',
      'offlineLabel': 'ஆஃப்லைன்',
      'cloudLabel': 'கிளவுட்',
      'topRecommendations': 'சிறந்த பரிந்துரைகள்',
      'recommendAgain': 'மீண்டும் பரிந்துரைக்கவும்',
      'specialty': 'சிறப்பு',
      'address': 'முகவரி',
      'phone': 'தொலைபேசி',
      'openNow': 'இப்போது திறந்துள்ளது',
      'callNow': 'இப்போது அழைக்கவும்',
      'chatOnWhatsApp': 'WhatsApp-ல் அரட்டை',
      'getDirections': 'திசை பெறவும்',
      'requestTimedOut': 'கோரிக்கை நேரம் முடிந்தது. மீண்டும் முயற்சிக்கவும்.',
      'somethingWentWrong': 'ஏதோ தவறு ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.',
      'justNow': 'இப்போது',
      'minutesAgo': '{value}நி முன்',
      'hoursAgo': '{value}மணி முன்',
      'daysAgo': '{value}நாள் முன்',
    },
    'te': {
      'plantName': 'మొక్క పేరు',
      'selectPlantName': 'మొక్క పేరును ఎంచుకోండి',
      'dashboardMorningLine':
          'పొలం పరిశీలన, నీటి ప్రణాళికలు మరియు ఉదయం నిర్ణయాలకు ఇది మంచి ఆరంభం.',
      'dashboardAfternoonLine':
          'ఈ మధ్యాహ్నం వేడి, పంట ఒత్తిడి మరియు మిగిలిన వ్యవసాయ పనులపై దృష్టి పెట్టండి.',
      'dashboardEveningLine':
          'ఈరోజు పంటలు, పశుసంవర్థక పరిస్థితి మరియు రేపటి పనితీరును సాయంత్రం ఒకసారి చూడండి.',
      'animalCow': 'ఆవు',
      'animalBuffalo': 'ఎద్దు',
      'animalGoat': 'మేక',
      'animalSheep': 'గొర్రె',
      'animalPig': 'పంది',
      'animalChicken': 'కోడి',
      'animalHorse': 'గుర్రం',
      'animalFish': 'చేప',
      'recommendedLabel': 'సిఫార్సు',
      'analyzedLabel': 'విశ్లేషించబడింది',
      'sourceLabel': 'మూలం',
      'offlineLabel': 'ఆఫ్లైన్',
      'cloudLabel': 'క్లౌడ్',
      'topRecommendations': 'ముఖ్య సిఫార్సులు',
      'recommendAgain': 'మళ్లీ సిఫార్సు చేయండి',
      'specialty': 'ప్రత్యేకత',
      'address': 'చిరునామా',
      'phone': 'ఫోన్',
      'openNow': 'ఇప్పుడు తెరిచి ఉంది',
      'callNow': 'ఇప్పుడే కాల్ చేయండి',
      'chatOnWhatsApp': 'WhatsApp లో చాట్',
      'getDirections': 'దారి చూడండి',
      'requestTimedOut': 'అభ్యర్థన సమయం ముగిసింది. మళ్లీ ప్రయత్నించండి.',
      'somethingWentWrong': 'ఏదో తప్పు జరిగింది. మళ్లీ ప్రయత్నించండి.',
      'justNow': 'ఇప్పుడే',
      'minutesAgo': '{value}ని క్రితం',
      'hoursAgo': '{value}గం క్రితం',
      'daysAgo': '{value}రోజుల క్రితం',
    },
  };

  static const Map<String, Map<String, String>> _dynamicValueTranslations = {
    'hi': {
      'Clear': 'साफ',
      'Cloudy': 'बादल',
      'Rain': 'बारिश',
      'Fog': 'कोहरा',
      'Thunderstorm': 'आंधी',
      'Snow': 'बर्फ',
      'Weather': 'मौसम',
      'Current location': 'वर्तमान स्थान',
      'Recommended': 'सिफारिश',
      'Analyzed': 'विश्लेषित',
      'Open': 'खुला',
      'Closed': 'बंद',
      'Apple': 'सेब',
      'Blueberry': 'ब्लूबेरी',
      'Cherry Including Sour': 'चेरी',
      'Corn Maize': 'मक्का',
      'Rice': 'धान',
      'rice': 'धान',
      'Maize': 'मक्का',
      'Wheat': 'गेहूं',
      'Grape': 'अंगूर',
      'Orange': 'संतरा',
      'Peach': 'आड़ू',
      'Pepper Bell': 'शिमला मिर्च',
      'Tomato': 'टमाटर',
      'Potato': 'आलू',
      'Raspberry': 'रास्पबेरी',
      'Soybean': 'सोयाबीन',
      'Squash': 'कद्दू वर्ग',
      'Strawberry': 'स्ट्रॉबेरी',
      'Sandy': 'बलुई',
      'Loamy': 'दोमट',
      'Clayey': 'चिकनी',
      'Seeds, fertilizers, pesticides': 'बीज, उर्वरक, कीटनाशक',
      'Cattle and Buffalo Specialist': 'गाय और भैंस विशेषज्ञ',
      'Pump and sprayer servicing': 'पंप और स्प्रेयर सर्विस',
    },
    'od': {
      'Clear': 'ସ୍ପଷ୍ଟ',
      'Cloudy': 'ମେଘାଚ୍ଛନ୍ନ',
      'Rain': 'ବର୍ଷା',
      'Fog': 'କୁହୁଡ଼ି',
      'Thunderstorm': 'ବଜ୍ରପାତ',
      'Snow': 'ହିମପାତ',
      'Weather': 'ପାଗ',
      'Current location': 'ବର୍ତ୍ତମାନ ଅବସ୍ଥାନ',
      'Recommended': 'ସୁପାରିଶ',
      'Analyzed': 'ବିଶ୍ଳେଷିତ',
      'Open': 'ଖୋଲା',
      'Closed': 'ବନ୍ଦ',
      'Apple': 'ସେବ',
      'Blueberry': 'ବ୍ଲୁବେରୀ',
      'Cherry Including Sour': 'ଚେରି',
      'Corn Maize': 'ମକା',
      'Rice': 'ଧାନ',
      'rice': 'ଧାନ',
      'Maize': 'ମକା',
      'Wheat': 'ଗହମ',
      'Grape': 'ଅଙ୍ଗୁର',
      'Orange': 'କମଳା',
      'Peach': 'ପୀଚ',
      'Pepper Bell': 'ବେଲ ଲଙ୍କା',
      'Tomato': 'ଟମାଟୋ',
      'Potato': 'ଆଳୁ',
      'Raspberry': 'ରାସ୍ପବେରୀ',
      'Soybean': 'ସୋୟାବିନ',
      'Squash': 'କୁମ୍ଭା ଶ୍ରେଣୀ',
      'Strawberry': 'ଷ୍ଟ୍ରବେରୀ',
      'Sandy': 'ବାଲୁକାମୟ',
      'Loamy': 'ଦୋଆବ',
      'Clayey': 'ଦଳିଆ',
      'Seeds, fertilizers, pesticides': 'ବୀଜ, ସାର, କୀଟନାଶକ',
      'Cattle and Buffalo Specialist': 'ଗାଈ ଓ ମହିଷ ବିଶେଷଜ୍ଞ',
      'Pump and sprayer servicing': 'ପମ୍ପ ଓ ସ୍ପ୍ରେୟର ସେବା',
    },
    'ta': {
      'Clear': 'தெளிவு',
      'Cloudy': 'மேகமூட்டம்',
      'Rain': 'மழை',
      'Fog': 'மூடுபனி',
      'Thunderstorm': 'இடி மின்னல்',
      'Snow': 'பனி',
      'Weather': 'வானிலை',
      'Current location': 'தற்போதைய இடம்',
      'Recommended': 'பரிந்துரை',
      'Analyzed': 'பகுப்பாய்வு',
      'Open': 'திறந்துள்ளது',
      'Closed': 'மூடப்பட்டது',
      'Apple': 'ஆப்பிள்',
      'Blueberry': 'புளூபெரி',
      'Cherry Including Sour': 'செர்ரி',
      'Corn Maize': 'மக்காச்சோளம்',
      'Rice': 'நெல்',
      'rice': 'நெல்',
      'Maize': 'மக்காச்சோளம்',
      'Wheat': 'கோதுமை',
      'Grape': 'திராட்சை',
      'Orange': 'ஆரஞ்சு',
      'Peach': 'பீச்',
      'Pepper Bell': 'குடை மிளகாய்',
      'Tomato': 'தக்காளி',
      'Potato': 'உருளைக்கிழங்கு',
      'Raspberry': 'ராஸ்பெரி',
      'Soybean': 'சோயாபீன்',
      'Squash': 'ஸ்க்வாஷ்',
      'Strawberry': 'ஸ்ட்ராபெரி',
      'Sandy': 'மணற்பாங்கு',
      'Loamy': 'கரிசல்',
      'Clayey': 'சருகு மண்',
      'Seeds, fertilizers, pesticides': 'விதைகள், உரங்கள், பூச்சிக்கொல்லிகள்',
      'Cattle and Buffalo Specialist': 'மாடு மற்றும் எருமை நிபுணர்',
      'Pump and sprayer servicing': 'பம்ப் மற்றும் தெளிப்பான் சேவை',
    },
    'te': {
      'Clear': 'స్పష్టం',
      'Cloudy': 'మేఘావృతం',
      'Rain': 'వర్షం',
      'Fog': 'మంచు',
      'Thunderstorm': 'పిడుగు వాన',
      'Snow': 'మంచుపాతం',
      'Weather': 'వాతావరణం',
      'Current location': 'ప్రస్తుత స్థానం',
      'Recommended': 'సిఫార్సు',
      'Analyzed': 'విశ్లేషించబడింది',
      'Open': 'తెరిచి ఉంది',
      'Closed': 'మూసివేసింది',
      'Apple': 'ఆపిల్',
      'Blueberry': 'బ్లూబెర్రీ',
      'Cherry Including Sour': 'చెర్రీ',
      'Corn Maize': 'మొక్కజొన్న',
      'Rice': 'వరి',
      'rice': 'వరి',
      'Maize': 'మొక్కజొన్న',
      'Wheat': 'గోధుమ',
      'Grape': 'ద్రాక్ష',
      'Orange': 'నారింజ',
      'Peach': 'పీచ్',
      'Pepper Bell': 'బెల్ పెప్పర్',
      'Tomato': 'టమాటా',
      'Potato': 'బంగాళాదుంప',
      'Raspberry': 'రాస్ప్‌బెర్రీ',
      'Soybean': 'సోయాబీన్',
      'Squash': 'స్క్వాష్',
      'Strawberry': 'స్ట్రాబెర్రీ',
      'Sandy': 'ఇసుక మట్టి',
      'Loamy': 'లోమీ మట్టి',
      'Clayey': 'మట్టికల మట్టి',
      'Seeds, fertilizers, pesticides': 'విత్తనాలు, ఎరువులు, పురుగుమందులు',
      'Cattle and Buffalo Specialist': 'ఆవు మరియు ఎద్దు నిపుణుడు',
      'Pump and sprayer servicing': 'పంపు మరియు స్ప్రేయర్ సేవ',
    },
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
      _englishMap = await _loadAssetMap('en');
      if (code == 'en') {
        _selectedMap = Map<String, String>.from(_englishMap);
        _map = Map<String, String>.from(_englishMap);
        return;
      }

      _selectedMap = await _loadAssetMap(code);
      _map = {
        ..._englishMap,
        ..._selectedMap,
      };
    } catch (_) {
      _selectedMap = const {};
      _map = Map<String, String>.from(_englishMap);
    }
  }

  Future<Map<String, String>> _loadAssetMap(String code) async {
    final raw = await rootBundle.loadString('assets/languages/$code.json');
    final sanitized = raw.startsWith('\ufeff') ? raw.substring(1) : raw;
    final decoded = jsonDecode(sanitized) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, _normalizeText(v.toString())));
  }

  String t(String key) {
    final english = _englishMap[key];
    final selected = _selectedMap[key];
    final localized = _extraLocalizedFallback[lang]?[key] ??
        _localizedFallback[lang]?[key];

    if (lang != 'en') {
      if (selected != null &&
          selected.isNotEmpty &&
          (english == null || selected != english)) {
        return _normalizeText(selected);
      }
      if (localized != null && localized.isNotEmpty) {
        return _normalizeText(localized);
      }
      if (selected != null && selected.isNotEmpty) {
        return _normalizeText(selected);
      }
    }

    return _normalizeText(
      english ?? localized ?? _fallback[key] ?? key,
    );
  }

  String displayAnimal(String value) => switch (value) {
        'Cow' => t('animalCow'),
        'Buffalo' => t('animalBuffalo'),
        'Goat' => t('animalGoat'),
        'Sheep' => t('animalSheep'),
        'Pig' => t('animalPig'),
        'Chicken' => t('animalChicken'),
        'Horse' => t('animalHorse'),
        'Fish' => t('animalFish'),
        _ => displayText(value),
      };

  String displayText(String value) {
    var text = _normalizeText(value);
    text = _prettifyPredictionText(text);
    final translations = _dynamicValueTranslations[lang];
    if (translations == null || text.isEmpty) return text;
    if (translations.containsKey(text)) return translations[text]!;

    final entries = translations.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text;
  }

  String _prettifyPredictionText(String input) {
    var text = input.trim();
    if (text.isEmpty) return text;

    if (text.contains('___')) {
      final parts = text.split('___');
      final crop = parts.first;
      final disease = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final cropText = _titleizePredictionPart(crop);
      final diseaseText = _titleizePredictionPart(disease);
      if (diseaseText.isEmpty) return cropText;
      if (diseaseText.toLowerCase() == 'healthy') return '$cropText Healthy';
      return '$cropText - $diseaseText';
    }

    if (RegExp(r'^[A-Za-z0-9,_() -]+$').hasMatch(text) &&
        (text.contains('_') || text.contains('(') || text.contains(')'))) {
      return _titleizePredictionPart(text);
    }

    return text;
  }

  String _titleizePredictionPart(String value) {
    final cleaned = value
        .replaceAll('_', ' ')
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ');
    final compact = cleaned
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    if (compact.isEmpty) return compact;
    return compact
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String format(String key, String fallback, Object value) =>
      (() {
        final raw = t(key);
        final template = raw == key ? fallback : raw;
        return template.replaceAll('{value}', value.toString());
      })();

  String greeting() {
    final h = DateTime.now().hour;

    if (h < 12) return t('goodMorning');
    if (h < 17) return t('goodAfternoon');

    return t('goodEvening');
  }

  String languageName(String code) =>
      _normalizeText(supported[code] ?? supported['en']!);

  String nativeLanguageName(String code) =>
      _normalizeText(nativeNames[code] ?? languageName(code));

  String languageFlag(String code) => _normalizeText(flags[code] ?? flags['en']!);

  String _normalizeText(String input) {
    var text = input;
    for (var i = 0; i < 3; i++) {
      if (!_looksMisencoded(text)) break;
      try {
        final repaired = utf8.decode(latin1.encode(text), allowMalformed: true);
        if (_misencodedScore(repaired) >= _misencodedScore(text)) break;
        text = repaired;
      } catch (_) {
        break;
      }
    }
    return text;
  }

  bool _looksMisencoded(String value) => _misencodedScore(value) > 0;

  int _misencodedScore(String value) {
    var score = 0;
    for (final token in const ['Ã', 'Â', 'à', 'ðŸ', 'â‚', 'â€”']) {
      score += token.allMatches(value).length;
    }
    return score;
  }
}
