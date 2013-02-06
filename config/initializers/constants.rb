SITE_URL = 'http://racetipper.herokuapp.com/'
COMPETITION_LOAD_QTY = 10

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