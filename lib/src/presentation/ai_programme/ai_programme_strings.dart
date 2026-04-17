/// Strings for the AI programme generation flow (context capture, loading, preview).
class AiProgrammeStrings {
  AiProgrammeStrings._();

  // Context capture
  static const String createTitle = 'Generate programme with AI';
  static const String createSubtitle = 'Answer a few questions to get a personalised plan. You can skip any step.';
  static const String goalTitle = 'What\'s your main goal?';
  static const String goalGetStronger = 'Get stronger';
  static const String goalBuildMuscle = 'Build muscle';
  static const String goalLoseWeight = 'Lose weight';
  static const String goalGeneralFitness = 'General fitness';
  static const String daysTitle = 'How many days per week can you train?';
  static const String blockedDaysTitle = 'Any days you can\'t train?';
  static const String blockedDaysHint = 'Select days to exclude (e.g. rest days)';
  static const String sessionLengthTitle = 'How long is each session?';
  static const String sessionLengthSuffix = ' min';
  static const String equipmentTitle = 'What equipment do you have?';
  static const String equipmentFullGym = 'Full gym';
  static const String equipmentHome = 'Home (dumbbells, bands, etc.)';
  static const String equipmentBodyweight = 'Bodyweight only';
  static const String ageTitle = 'Your age (optional)';
  static const String ageHint = 'Helps tailor volume and recovery';
  static const String injuriesTitle = 'Injuries or limitations (optional)';
  static const String injuriesHint = 'e.g. lower back issue, avoid heavy squatting';
  static const String injuriesEmphasis = 'This is used to tailor your programme. Include which side (e.g. left shoulder), what aggravates it, and what you\'ve been told to avoid. The more detail, the better we can adapt exercises and coaching.';
  static const String additionalContextTitle = 'Preferences (optional)';
  static const String additionalContextHint = 'e.g. I don\'t like squats, prefer short sessions, love deadlifts';
  static const String additionalEmphasis = 'What you enter here directly shapes your programme. List exercise preferences, dislikes, or anything else that should influence your plan.';
  static const String startDateTitle = 'When do you want to start?';
  static const String startDateHint = 'Your first workout will be scheduled from this date. You can change it later.';
  static const String startDatePickerHelp = 'Select programme start date';
  static const String readyToGenerateTitle = 'Ready to generate';
  static String readyToGenerateSummary(int days, int minutes, String startDay) =>
      'We\'ll create a $days-day programme, $minutes min per session, starting $startDay, based on your goals and equipment.';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String generate = 'Generate programme';

  // Loading (sequence for AnimatedSwitcher)
  static const String loadingMessage1 = 'Understanding your goals...';
  static const String loadingMessage2 = 'Reviewing your notes...';
  static const String loadingMessage3 = 'Selecting exercises...';
  static const String loadingMessage4 = 'Building your schedule...';
  static const String loadingMessage5 = 'Adding the finishing touches...';

  // Preview
  static const String previewTitle = 'Your programme';
  static const String acceptProgramme = 'Accept';
  static const String makeAdjustment = 'Make adjustment';
  static const String adjustSheetTitle = 'What would you like to adjust?';
  static const String adjustChangeDates = 'Change workout dates';
  static const String adjustChangeDatesCaption = 'Move a session or shift your whole schedule';
  static const String adjustSwapExercise = 'Swap an exercise';
  static const String adjustSwapExerciseCaption = 'Replace an exercise with one that suits you better';
  static const String adjustSetsReps = 'Change sets, reps or weight';
  static const String adjustSetsRepsCaption = 'Fine-tune the volume and intensity';
  // Legacy — kept for reference, not used in UI
  static const String startProgramme = 'Start this programme';
  static const String adjustSomething = 'Adjust something';
  static const String workoutsThisWeek = 'Workouts this week';
  /// When programme starts in a future week (not "this week").
  static const String yourWorkouts = 'Your workouts';
  static const String deloadNote = 'Deload';
  static const String progressionNote = 'Progression';

  // Teaser (entry card on Programs screen)
  static const String teaserTitle = 'Build my programme';
  static const String teaserBody =
      'Tell us your goals, schedule, and what you\'re working around — we\'ll create a plan built specifically for you.';
  static const String teaserFootnote =
      'Premium feature · 14-day free trial (where available)';
  static const String gateAppBarTitle = 'AI programme';
  static const String gateBack = 'Back';
  static const String teaserCta = 'Upgrade to unlock';

  // Intro (framing screen before step 1)
  static const String introHeadline = 'Let\'s build your programme';
  static const String introBody =
      'We\'ll ask you a few quick questions. The more honest you are, the better your programme will be.';
  static const String introSubline = 'This isn\'t a template — it\'s built around you.';
  static const String introCta = 'Let\'s go →';

  // Step headlines and sub-captions (conversational)
  static const String goalHeadline = 'What are you training for?';
  static const String goalCaption =
      'This shapes everything — your exercises, volume, and how we progress you.';
  static const String daysHeadline = 'How many days a week can you commit to?';
  static const String daysCaption = 'Be realistic — consistency beats intensity every time.';
  static const String blockedDaysHeadline = 'Which days don\'t work for you?';
  static const String blockedDaysCaption = 'We\'ll build your schedule around these.';
  static String reflectionDays(int n) => 'So that\'s $n days a week.';
  static const String blockedDaysSuggest = 'We suggest training on these days:';
  static const String blockedDaysTapHint = 'Tap any day to swap it out.';
  static const String sessionLengthHeadline = 'How long have you got each session?';
  static const String sessionLengthCaption =
      'We\'ll fit a full workout into whatever time you have.';
  static const String equipmentHeadline = 'What are you working with?';
  static const String equipmentCaption = 'We\'ll only include exercises you can actually do.';
  static const String experienceHeadline = 'How would you describe your training experience?';
  static const String experienceCaption =
      'This helps us get the tone right — we won\'t talk down to you or assume you\'re new.';
  static const String experienceNew = 'New to training';
  static const String experienceSome = 'Some experience';
  static const String experienceRegular = 'I train regularly';
  static const String experienceSkipHint = 'Skip this if you prefer — we\'ll use neutral language.';
  static String reflectionEquipment(int days, int minutes) =>
      'Building your $days-day, $minutes-min programme.';
  static const String ageHeadline = 'How old are you?';
  static const String ageCaption = 'Helps us tailor recovery time and volume. Optional.';
  static const String ageScrollHint = 'Scroll and tap your age — no typing needed.';
  static const String injuriesHeadline = 'Anything we should work around?';
  static const String injuriesCaption =
      'Injuries, pain, or movements to avoid. The more specific, the better we can adapt.';
  static const String injuryFollowUpShoulder = 'Which shoulder?';
  static const String injurySideLeft = 'Left';
  static const String injurySideRight = 'Right';
  static const String injurySideBoth = 'Both';
  static const String preferencesHeadline = 'Make it yours.';
  static const String preferencesPersonaliseLine =
      'This is what makes your plan personal — the more you share, the better we can tailor it.';
  static const String preferencesCaption =
      'Exercises you love, things you\'d rather avoid, or anything else that should shape your plan. Don\'t hold back — this is what makes it personal.';
  static const String preferencesPlaceholder =
      'e.g. hate burpees, love deadlifts, prefer not to train legs on Mondays...';
  static const String readyHeadline = 'Here\'s what we\'re building';
  static const String readyCaption =
      'Your programme is tailored to everything above. We\'ll start light and build from there.';
  static const String readyCaptionRationale =
      'After we build it, you\'ll see why each workout and exercise was chosen for you.';
  static const String buildMyProgrammeCta = '✦ Build my programme';

  // Reveal
  static const String revealReady = 'Your programme is ready';
  static const String revealPreferencesNoted = 'Your preferences noted';
  static const String tellMeAboutMyProgramme = '✦ Tell me about my programme';

  // About your programme screen
  static const String aboutTitle = 'About your programme';
  static const String aboutWhyThisProgrammeTitle = 'Why this programme';
  static const String aboutWorkoutBreakdownsTitle = 'Why each workout and exercise';
  static const String aboutWorkoutBreakdownsCaption =
      'Purpose of each session and why these exercises were chosen for you.';
}
