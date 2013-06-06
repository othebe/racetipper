SITE_URL = 'http://racetipper.herokuapp.com/'
COMPETITION_LOAD_QTY = 10
ADMIN_ID = 2

STATUS = {
	:DELETED => 0,
	:ACTIVE => 1,
	:INACTIVE => 2,
	:PRIVATE => 3
}

RIDER_RESULT_STATUS = {
	:ACTIVE => 1,
	:DNS => 2,
	:DNF => 3
}

ARTICLE_TYPE = {
	:ARTICLE => 1,
	:GALLERY => 2
}

URL_TYPE = {
	:IMAGE => 1,
	:VIDEO => 2
}

DEFAULT = {
	:RACE_IMG => '/assets/default_competition.jpg',
	:COMPETITION_IMG => '/assets/default_competition.jpg',
	:STAGE_IMG => '/assets/default_competition.jpg',
	:USER_IMG => '/assets/default_user.jpg'
}

#Score modifiers. (Think of them as time modifiers)
#Penalties are positive (More severe = higher).
#Bonuses are negative (lower = better)
SCORE_MODIFIER = {
	:DNS => 100,
	:DNF => 100,
	:DEFAULT => 90
}

#Competition types
#USER - User created competitions (Default)
#GLOBAL - Site wide competition created for every race
COMPETITION_TYPE = {
	:USER => 1,
	:GLOBAL => 2
}

#Stage types
STAGE_TYPE = {
	:F => 'Flat',
	:MM => 'Medium Mountains',
	:HM => 'High Mountains',
	:MF => 'Mountain Finish',
	:ITT => 'Individual Time Trial',
	:TTT => 'Team Time Trial'
}

#Report type
REPORT_TYPE = {
	:STAGE => 1,
	:STAGE_PREVIEW => 2,
	:TIPPING => 3
}

#Partner access tokens
PARTNER_ACCESS_TOKEN = {
	:CYCLINGTIPS => '8JUDm7cFiVGLIqiWbkVs6S2gxxOvAvbl'
}