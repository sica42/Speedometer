---@class Speedometer
Speedometer = Speedometer or {}

Speedometer.zone_sizes = {
	-- Kalimdor
	[ "Ashenvale" ] = {
		height = 3843.749877929687,
		width = 5766.66638183594,
	},
	[ "Aszhara" ] = {
		height = 3381.2498779296902,
		width = 5070.8327636718695,
	},
	[ "Barrens" ] = {
		height = 6756.24987792969,
		width = 10133.3330078125,
	},
	[ "Darkshore" ] = {
		height = 4366.66650390625,
		width = 6549.9997558593805,
	},
	[ "Darnassis" ] = {
		height = 705.7294921875,
		width = 1058.33325195312,
	},
	[ "Desolace" ] = {
		height = 2997.916564941411,
		width = 4495.8330078125,
	},
	[ "Durotar" ] = {
		height = 3524.9998779296902,
		width = 5287.49963378906,
	},
	[ "Dustwallow Marsh" ] = {
		height = 3499.99975585937,
		width = 5250.000061035156,
	},
	[ "Felwood" ] = {
		height = 3833.33325195312,
		width = 5749.99963378906,
	},
	[ "Feralas" ] = {
		height = 4633.3330078125,
		width = 6949.9997558593805,
	},
	[ "Moonglade" ] = {
		height = 1539.5830078125,
		width = 2308.33325195313,
	},
	[ "Mulgore" ] = {
		height = 3424.999847412109,
		width = 5137.49987792969,
	},
	[ "Ogrimmar" ] = {
		height = 935.41662597657,
		width = 1402.6044921875,
	},
	[ "Silithus" ] = {
		height = 2322.916015625,
		width = 3483.333984375,
	},
	[ "Stonetalon Mountains" ] = {
		height = 3256.2498168945312,
		width = 4883.33312988282,
	},
	[ "Tanaris" ] = {
		height = 4600.0,
		width = 6899.999526977539,
	},
	[ "Teldrassil" ] = {
		height = 3393.75,
		width = 5091.66650390626,
	},
	[ "Thousand Needles" ] = {
		height = 2933.3330078125,
		width = 4399.999694824219,
	},
	[ "Thunder Bluff" ] = {
		height = 695.833312988286,
		width = 1043.749938964844,
	},
	[ "Ungoro Crater" ] = {
		height = 2466.66650390625,
		width = 3699.9998168945312,
	},
	[ "Winterspring" ] = {
		height = 4733.3332519531195,
		width = 7099.999847412109,
	},
	-- Eastern Kingdoms
	[ "Alterac Valley" ] = {
		height = 1866.666656494141,
		width = 2799.999938964841,
	},
	[ "Arathi Highlands" ] = {
		height = 2399.99992370606,
		width = 3599.999877929687,
	},
	[ "Badlands" ] = {
		height = 1658.33349609375,
		width = 2487.5,
	},
	[ "Blackrock Mountain" ] = {
		height = 470,
		width = 710,
	},
	[ "Blackrock Spire" ] = {
		height = 595,
		width = 885,
	},
	[ "Blasted Lands" ] = {
		height = 2233.333984375,
		width = 3349.9998779296902,
	},
	[ "Burning Steppes" ] = {
		height = 1952.08349609375,
		width = 2929.166595458989,
	},
	[ "Deadwind Pass" ] = {
		height = 1666.6669921875,
		width = 2499.999938964849,
	},
	[ "Dun Morogh" ] = {
		height = 3283.33325195312,
		width = 4924.9997558593805,
	},
	[ "Duskwood" ] = {
		height = 1800.0,
		width = 2699.999938964841,
	},
	[ "Eastern Plaguelands" ] = {
		height = 2581.24975585938,
		width = 3870.83349609375,
	},
	[ "Elwynn Forest" ] = {
		height = 2314.5830078125,
		width = 3470.83325195312,
	},
	[ "Gilneas" ] = {
		height = 2430,
		width = 3670,
	},
	[ "Hilsbrad Foothills" ] = {
		height = 2133.33325195313,
		width = 3199.9998779296902,
	},
	[ "The Hinterlands" ] = {
		height = 2566.6666259765598,
		width = 3850.0,
	},
	[ "Ironforge" ] = {
		height = 527.6044921875,
		width = 790.625061035154,
	},
	[ "Lapidis Isle" ] = {
		height = 1917,
		width = 2898,
	},
	[ "Loch Modan" ] = {
		height = 1839.5830078125,
		width = 2758.3331298828098,
	},
	[ "Redridge Mountains" ] = {
		height = 1447.916015625,
		width = 2170.83325195312,
	},
	[ "Searing Gorge" ] = {
		height = 1487.49951171875,
		width = 2231.249847412109,
	},
	[ "Silverpine Forest" ] = {
		height = 2799.9998779296902,
		width = 4199.9997558593805,
	},
	[ "Stormwind City" ] = {
		height = 1161, --896.3544921875,
		width = 1742, --1344.2708053588917,
	},
	[ "Stranglethorn Vale" ] = {
		height = 4254.166015625,
		width = 6381.2497558593805,
	},
	[ "Swamp of Sorrows" ] = {
		height = 1529.1669921875,
		width = 2293.75,
	},
	[ "Thalassian Highlands" ] = {

	},
	[ "Tirisfal Glades" ] = {
		height = 3012.499816894536,
		width = 4518.74987792969,
	},
	[ "Undercity" ] = {
		height = 640.10412597656,
		width = 959.3750305175781,
	},
	[ "Western Plaguelands" ] = {
		height = 2866.666534423828,
		width = 4299.999908447271,
	},
	[ "Westfall" ] = {
		height = 2333.3330078125,
		width = 3499.9998168945312,
	},
	[ "Wetlands" ] = {
		height = 2756.25,
		width = 4135.416687011719,
	},
}
