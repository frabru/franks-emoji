#!/bin/sh -e

cd "$( dirname "$0" )"
cd ..

numargs() {
	printf '%d\n' "$#"
}

attribute() {
	while [ $# -gt 0 ] ; do
		printf ' %s="%s"' "$1" "$(
		sed -e '
	:start
	$ ! {
		N
		b start
	}
	s/&/\&amp;/g
	s/</\&lt;/g
	s/>/\&gt;/g
	s/"/&quot;/g
	s/\n/&#xa;/g
' <<ARG
$2
ARG
)"
		shift 2
	done
}

cdata() {
	sed -e '
	s/&/\&amp;/g
	s/</\&lt;/g
	s/>/\&gt;/g
' <<ARG
$*
ARG
}

attr_data() {
	sed -e '
	:start
	$ ! {
		N
		b start
	}
	s/&/\&amp;/g
	s/</\&lt;/g
	s/>/\&gt;/g
	s/"/&quot;/g
	s/\n/&#xa;/g
' <<ARG
$*
ARG
}

first_title_element() {
	grep -o -m 1 -e '<title\>[^>]*>[^<]*</title>' -- "$1"
}

title() {
	first_title_element "$1" |
	sed -e '
		s/<[^>]*>//g
		s/"/\&quot;/g
		/^$/ i\'"
${1#.svg}"
}

## start_chart TITLE
start_chart() {
	cat <<E
<?xml version="1.0" encoding="UTF-8"?>
<svg viewBox="-$TILE_WIDTH 0 $( printf '%d %d' $(( $TILE_WIDTH * ( $NUM_COLS + 1 ) )) $(( $TILE_HEIGHT * $NUM_ROWS )) )" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<title>$( cdata "$1" )</title>
<style type="text/css"><![CDATA[
a:hover rect {
	fill: #4455ff;
}
.sub_items {
	visibility: hidden;
}
.main_item:hover .sub_items {
	visibility: visible;
}
]]></style>
E
}

end_chart() {
cat <<E
</svg>
E
}

## chart_item ROW COLUMN MAIN_FILENAME [SUB_FILENAMES...]
chart_item() {
	POS_COL="$1"
	POS_ROW="$2"
	shift 2
	cat <<E
<g transform="translate($(( $POS_COL * $TILE_WIDTH )) 0)" class="main_item">
	<g transform="translate(0 $(( $POS_ROW * $TILE_HEIGHT )))">
E
	if [ $# -gt 1 ] ; then
		cat <<E
		<path fill="#ccc" d="M1 0v4l-2 -2"/>
E
	fi
	cat <<E
		<a xlink:href="$( attr_data "$1" )" xlink:title="$( title "$1" )">
			<rect x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT" rx="2" ry="2" fill="none"/>
			<image xlink:href="$( attr_data "$1" )" x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT"/>
		</a>
	</g>
E
	if [ $# -gt 1 ] ; then
		shift
		if [ "$(( $POS_ROW + $# ))" -gt "$DIV" ] ; then
			BLOCK_ROW="$(( $DIV - $# ))"
		else
			BLOCK_ROW="$POS_ROW"
		fi
		cat <<E
	<g transform="translate(-$TILE_WIDTH $(( $BLOCK_ROW * $TILE_HEIGHT )))" class="sub_items">
		<rect fill="#fff" stroke="#ccc" stroke-width="1" x="-0.5" y="-0.5" width="$(( $TILE_WIDTH + 1 ))" height="$(( $# * $TILE_HEIGHT + 1 ))" rx="2.5" ry="2.5"/>
E
		REL_COL=0
		REL_ROW=0
		for file in "$@" ; do
			cat <<E
		<g transform="translate(0 $(( $REL_ROW * $TILE_HEIGHT )))">
			<a xlink:href="$( attr_data "$file" )" xlink:title="$( title "$file" )">
				<rect x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT" rx="2" ry="2" fill="none"/>
				<image xlink:href="$( attr_data "$file" )" x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT"/>
			</a>
		</g>
E
			REL_ROW="$(( $REL_ROW + 1 ))"
		done
cat <<E
	</g>
E
	fi
cat <<E
</g>
E
}

## chart_item_cp CODEPOINT
chart_item_cp() {
	CP="$1"
	UCP="$( printf 'U+%04X' "$1" )"
	set --
	for file in "$UCP"_*.svg "$UCP-VS16"_*.svg ; do
		if ! [ -e "$file" ] ; then
			continue
		fi
		set -- "$@" "$file"
	done
	for file in "$UCP"-*.svg ; do
		case "$file" in
			"$UCP-VS16"_*)
				continue
				;;
		esac
		if ! [ -e "$file" ] ; then
			continue
		fi
		set -- "$@" "$file"
	done
	if [ $# = 0 ] ; then
		return 0
	fi
	chart_item "$(( $CP / $DIV - $START_COL ))" "$(( $CP % $DIV ))" "$@"

}

## create_chart MIN_UCP..MAX_UCP TITLE
create_chart() {

	CP_MIN="${1%%..*}"
	CP_MIN="${CP_MIN#U+}"
	CP_MAX="${1#*..}"
	CP_MAX="${CP_MAX#U+}"

	CP_MIN="$( printf '%d\n' "0x$CP_MIN" )"
	CP_MAX="$( printf '%d\n' "0x$CP_MAX" )"

	TILE_WIDTH=10
	TILE_HEIGHT=10

	CHART_NAME="$2"

	DIV=16

	OFFSET="$(( $CP_MIN % $DIV ))"
	START_COL="$(( $CP_MIN / $DIV ))"
	END_COL="$(( $CP_MAX / $DIV ))"

	NUM_COLS="$(( $END_COL - $START_COL + 1 ))"
	NUM_ROWS="$DIV"

	start_chart "$CHART_NAME"
	for CODEPOINT in $( seq "$CP_MIN" "$CP_MAX" ) ; do
		chart_item_cp "$CODEPOINT"
	done
	end_chart

	COL=
}

## chart_item_cc COUNTRY_CODE
chart_item_cc() {
	set -- "$1.svg" "$1"-*.svg
	if ! [ -e "$1" ] ; then
		return 0
	fi
	if ! [ -e "$2" ] ; then
		set -- "$1"
	fi
	read x CP1 CP2 xx <<ARG
$( od -N 2 -t d1 <<INP
$1
INP
)
ARG
	chart_item "$(( $CP1 - 65 ))" "$(( $CP2 - 65 ))" "$@"
}

create_chart_flags() {
	TILE_WIDTH=13
	TILE_HEIGHT=10

	num_lang_codes="$( numargs [[:lower:]][[:lower:]][[:lower:]].svg )"
	num_zwj_seq="$( numargs U+*.svg )"

	NUM_COLS="$(( 26 + 1 + ( $num_lang_codes / 26 ) + 1 + ( $num_zwj_seq / 26 ) ))"
	NUM_ROWS=26
	start_chart Flags
	for file in [[:upper:]][[:upper:]].svg ; do
		chart_item_cc "$( basename "$file" .svg )"
	done
	i=0
	for file in [[:lower:]][[:lower:]][[:lower:]].svg ; do
		chart_item "$(( $i / 26 + 26 ))" "$(( $i % 26 ))" "$file"
		i="$(( $i + 1 ))"
	done
	
	i=0
	for file in U+*.svg ; do
		chart_item "$(( $i / 26 + 26 + 1 + ( $num_lang_codes / 26 ) ))" "$(( $i % 26 ))" "$file"
		i="$(( $i + 1 ))"
	done
	end_chart
}

cd ./emoji
create_chart U+2300..U+23FF 'Miscellaneous Technical' | tee index_U+2300_Miscellaneous_Technical.svg
create_chart U+2460..U+24FF 'Enclosed Alphanumerics' | tee index_U+2460_Enclosed_Alphanumerics.svg
create_chart U+2600..U+26FF 'Miscellaneous Symbols' | tee index_U+2600_Miscellaneous_Symbols.svg
# create_chart U+2700..U+27BF 'Dingbats' | tee index_U+2700_Dingbats.svg
create_chart U+2900..U+297F 'Supplemental Arrows-B' | tee index_U+2900_Supplemental_Arrows-B.svg
create_chart U+2B00..U+2BFF 'Miscellaneous Symbols and Arrows' | tee index_U+2B00_Miscellaneous_Symbols_and_Arrows.svg
# create_chart U+3200..U+32FF 'Enclosed CJK Letters and Months' | tee index_U+3200_Enclosed_CJK_Letters_and_Months.svg
# create_chart U+1F000..U+1F02F 'Mahjong Tiles' | tee index_U+1F000_Mahjong_Tiles.svg
# create_chart U+1F0A0..U+1F0FF 'Playing Cards' | tee index_U+1F0A0_Playing_Cards.svg
# create_chart U+1F100..U+1F1FF 'Enclosed Alphanumeric Supplement' | tee index_U+1F100_Enclosed_Alphanumeric_Supplement.svg
# create_chart U+1F200..U+1F2FF 'Enclosed Ideographic Supplement' | tee index_U+1F200_Enclosed_Ideographic_Supplement.svg
create_chart U+1F300..U+1F5FF 'Miscellaneous Symbols and Pictographs' | tee index_U+1F300_Miscellaneous_Symbols_and_Pictographs.svg
create_chart U+1F600..U+1F64F 'Emoticons' | tee index_U+1F600_Emoticons.svg
# create_chart U+1F650..U+1F67F 'Ornamental Dingbats' | tee index_U+1F650_Ornamental_Dingbats.svg
# create_chart U+1F680..U+1F6FF 'Transport and Map Symbols' | tee index_U+1F680_Transport_and_Map_Symbols.svg
create_chart U+1F780..U+1F7FF 'Geometric Shapes Extended' | tee index_U+1F780_Geometric_Shapes_Extended.svg
# create_chart U+1F900..U+1F9FF 'Supplemental Symbols and Pictographs' | tee index_U+1F900_Supplemental_Symbols_and_Pictographs.svg
# create_chart U+1FA70..U+1FAFF 'Symbols and Pictographs Extended-A' | tee index_U+1FA70_Symbols_and_Pictographs_Extended-A.svg
cd ..

cd ./flags
create_chart_flags | tee index_Flags.svg

