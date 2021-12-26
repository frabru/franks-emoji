#!/bin/sh -e

cd "$( dirname "$0" )"
cd ..

format="${1-svg}"

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
	"start_chart_$format" "$@"
}
start_chart_md() {
	printf '# %s\n\n' "$1"
	for i in $( seq $NUM_ROWS ) ; do
		printf %s '| &#x2003; '
	done
	printf '%s\n' '|'
	for i in $( seq $NUM_ROWS ) ; do
		printf %s "| :---: "
	done
	printf '%s\n' '|'
	TABLE_ROW=0
	TABLE_COL=0
	POST_TABLE_CONTENT=
}
start_chart_xhtml() {
	cat <<E
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>$( cdata "$1" )</title>
	<style type="text/css"><![CDATA[
img {
	vertical-align: middle;
}
a:hover img {
	background: #4455ff;
}
.sub_items {
	visibility: hidden;
	position: absolute;
	background: #ffffff;
	border: 2px #cccccc solid;
	padding: 2px;
}
.has_sub_items {
	border-bottom: solid 2px #cccccc;
}
.main_item:hover .sub_items {
	visibility: visible;
}
	]]></style>
</head>
<body>
<table>
<tbody>
<tr>
E
TABLE_ROW=0
TABLE_COL=0
}
start_chart_svg() {
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
	"end_chart_$format" "$@"
}
end_chart_md() {
	printf '%s\n\n%s\n' '|' "$POST_TABLE_CONTENT"
}
end_chart_xhtml() {
	cat <<E
</tr>
</tbody>
</table>
</body>
</html>
E
}
end_chart_svg() {
cat <<E
</svg>
E
}

## chart_item ROW COLUMN MAIN_FILENAME [SUB_FILENAMES...]
chart_item() {
	"chart_item_$format" "$@"
}
chart_item_md() {
	POS_ROW="$1"
	POS_COL="$2"
	shift 2
	while [ "$TABLE_ROW" -lt "$POS_ROW" ] ; do
		while [ "$TABLE_COL" -lt "$NUM_ROWS" ] ; do
			printf %s '| &#160; '
			TABLE_COL=$(( TABLE_COL + 1 ))
		done
		printf '%s\n' '|'
		TABLE_ROW=$(( TABLE_ROW + 1 ))
		TABLE_COL=0
	done
	while [ "$TABLE_COL" -lt "$POS_COL" ] ; do
		printf %s '| &#160; '
		TABLE_COL=$(( TABLE_COL + 1 ))
	done
	if [ $# -gt 1 ] ; then
		printf %s "| <a href=\"$( attr_data "#$(
tr '[:upper:]' '[:lower:]' <<ARG |
${1%%[_.]*}
ARG
tr -d +
)" )\" title=\"$( title "$1" )\"><img src=\"$( attr_data "$1" )\" x=\"0\" y=\"0\" width=\"$TILE_WIDTH\" height=\"$TILE_HEIGHT\"/></a>"
		POST_TABLE_CONTENT="$POST_TABLE_CONTENT

## ${1%%[_.]*}
"
		for sub_item in "$@" ; do
			POST_TABLE_CONTENT="$POST_TABLE_CONTENT
- <a href=\"$( attr_data "$sub_item" )\" title=\"$( title "$sub_item" )\"><img src=\"$( attr_data "$sub_item" )\" x=\"0\" y=\"0\" width=\"$TILE_WIDTH\" height=\"$TILE_HEIGHT\"/></a>"
		done
	else
		printf %s "| <a href=\"$( attr_data "$1" )\" title=\"$( title "$1" )\"><img src=\"$( attr_data "$1" )\" x=\"0\" y=\"0\" width=\"$TILE_WIDTH\" height=\"$TILE_HEIGHT\"/></a>"
	fi
	TABLE_COL=$(( TABLE_COL + 1 ))
}
chart_item_xhtml() {
	POS_ROW="$1"
	POS_COL="$2"
	shift 2
	while [ "$TABLE_ROW" -lt "$POS_ROW" ] ; do
		if [ "$TABLE_COL" = 0 ] ; then
			cat <<E
<td>&#160;</td>
E
		fi
		cat <<E
</tr>
<tr>
E
		TABLE_ROW=$(( TABLE_ROW + 1 ))
		TABLE_COL=0
	done
	while [ "$TABLE_COL" -lt "$POS_COL" ] ; do
		cat <<E
<td>&#160;</td>
E
		TABLE_COL=$(( TABLE_COL + 1 ))
	done
	cat <<E
<td class="main_item$( if [ $# -gt 1 ] ; then printf ' %s' has_sub_items ; fi )">
<a href="$( attr_data "$1" )" title="$( title "$1" )">
	<img src="$( attr_data "$1" )" x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT"/>
</a>
E
	if [ $# -gt 1 ] ; then
		shift
		cat <<E
<div class="sub_items">
E
		for file in "$@" ; do
			cat <<E
	<a href="$( attr_data "$file" )" title="$( title "$file" )"><img src="$( attr_data "$file" )" x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT"/></a>
E
		done
		cat <<E
</div>
E
	fi
	cat <<E
</td>
E
	TABLE_COL=$(( TABLE_COL + 1 ))
}
chart_item_svg() {
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
		SUB_COLS=$(( ( $# - 1 ) / $NUM_ROWS + 1 ))
		SUB_ROWS=$(( ( $# - 1 ) / $SUB_COLS + 1 ))
		if [ "$(( $POS_ROW + $SUB_ROWS ))" -gt "$NUM_ROWS" ] ; then
			BLOCK_ROW="$(( $NUM_ROWS - $SUB_ROWS ))"
		else
			BLOCK_ROW="$POS_ROW"
		fi
		cat <<E
	<g transform="translate(-$(( $TILE_WIDTH * $SUB_COLS )) $(( $BLOCK_ROW * $TILE_HEIGHT )))" class="sub_items">
		<rect fill="#fff" stroke="#ccc" stroke-width="1" x="-0.5" y="-0.5" width="$(( $SUB_COLS * $TILE_WIDTH + 1 ))" height="$(( $SUB_ROWS * $TILE_HEIGHT + 1 ))" rx="2.5" ry="2.5"/>
E
		REL_COL=0
		REL_ROW=0
		for file in "$@" ; do
			cat <<E
		<g transform="translate($(( $REL_COL * $TILE_WIDTH )) $(( $REL_ROW * $TILE_HEIGHT )))">
			<a xlink:href="$( attr_data "$file" )" xlink:title="$( title "$file" )">
				<rect x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT" rx="2" ry="2" fill="none"/>
				<image xlink:href="$( attr_data "$file" )" x="0" y="0" width="$TILE_WIDTH" height="$TILE_HEIGHT"/>
			</a>
		</g>
E
			REL_ROW="$(( $REL_ROW + 1 ))"
			if [ "$REL_ROW" -ge "$SUB_ROWS" ] ; then
				REL_COL="$(( $REL_COL + 1 ))"
				REL_ROW=0
			fi
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

	TILE_WIDTH=18
	TILE_HEIGHT=18

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
	TILE_WIDTH=26
	TILE_HEIGHT=20

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

write_chart() {
	create_chart "$1" "$2" | tee "index_${1%%..*}_$(
	tr ' ' _ <<ARG
$2
ARG
	).$format"
}

cd ./emoji
# write_chart U+0020..U+007F 'Basic Latin'
# write_chart U+00A0..U+00FF 'Latin-1 Supplement'
write_chart U+2000..U+206F 'General Punctuation'
write_chart U+2100..U+214F 'Letterlike Symbols'
write_chart U+2190..U+21FF 'Arrows'
write_chart U+2300..U+23FF 'Miscellaneous Technical'
write_chart U+2460..U+24FF 'Enclosed Alphanumerics'
write_chart U+25A0..U+25FF 'Geometric Shapes'
write_chart U+2600..U+26FF 'Miscellaneous Symbols'
# write_chart U+2700..U+27BF 'Dingbats'
write_chart U+2900..U+297F 'Supplemental Arrows-B'
write_chart U+2B00..U+2BFF 'Miscellaneous Symbols and Arrows'
write_chart U+3000..U+303F 'CJK Symbols and Punctuation'
# write_chart U+3200..U+32FF 'Enclosed CJK Letters and Months'
# write_chart U+1F000..U+1F02F 'Mahjong Tiles'
# write_chart U+1F0A0..U+1F0FF 'Playing Cards'
# write_chart U+1F100..U+1F1FF 'Enclosed Alphanumeric Supplement'
# write_chart U+1F200..U+1F2FF 'Enclosed Ideographic Supplement'
write_chart U+1F300..U+1F5FF 'Miscellaneous Symbols and Pictographs'
write_chart U+1F600..U+1F64F 'Emoticons'
# write_chart U+1F680..U+1F6FF 'Transport and Map Symbols'
write_chart U+1F780..U+1F7FF 'Geometric Shapes Extended'
# write_chart U+1F900..U+1F9FF 'Supplemental Symbols and Pictographs'
# write_chart U+1FA70..U+1FAFF 'Symbols and Pictographs Extended-A'
cd ..

cd ./flags
create_chart_flags | tee "index_Flags.$format"

