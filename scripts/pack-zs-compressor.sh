#!/bin/bash
#
# This script takes a pack file and a diff dir ( setup w/ pack-zs-extract.sh ) and rebuilds a new modified pack file from diff

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR="${SCRIPT_DIR}/.."
WILD_BITS_TOOLS="${WORK_DIR}/builds/wildbits-tools.exe"

display_help() {
  echo "Usage: $0 [option...] " >&2
  echo
  echo "  -h, --help                 Show help message"

  echo "  -p, --pack                 Path to base pack file ( From pack-zs-extract.sh ) (Required)"
  echo "  -d, --dict                 Path to pack.zsdic generated from romfs (Required)" #TODO: Autogen
  echo "  -f, --folder               Path to diff folder containing mod changes ( From pack-zs-extract.sh ) (Required)"
  echo "  -o, --out                  Path to output pack.zs to use for mod (Required)" #TODO: Use based on passed pack?
  echo "  -z, --zstd                 Path to zstd install (Required)"

  echo
  echo "Example: $0 -p Weapon_Sword_166.pack -d Pack/pack.zsdic -f Weapon_Sword_166/ -o Weapon_Sword_166.pack.zs"
}

while getopts ":hp:d:f:o:z:" opt; do
  case ${opt} in
    h|--help )
      display_help
      exit 0
      ;;
    p|--pack )
      PACK_FILE=$OPTARG
      ;;
    d|--dict )
      DICT_FILE=$OPTARG
      ;;
    f|--folder )
      DIFF_FOLDER=$OPTARG
      ;;
    o|--out )
      OUT_PACK_ZS=$OPTARG
      ;;
    z|--zstd )
      ZSTD=$OPTARG
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      display_help
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      display_help
      exit 1
      ;;
  esac
done

# Check if required arguments are present
if [[ -z "${PACK_FILE}" || -z ${DICT_FILE} || -z "${DIFF_FOLDER}" || -z "${OUT_PACK_ZS}" || -z "${ZSTD}" ]]; then
  echo "Missing required argument: --pack or --dict or --folder or --out or --zstd" 1>&2
  display_help
  exit 1
fi

#TODO: Check files of correct format

TMP_DIR="${WORK_DIR}/tmp/"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

OUT_NAME=$(basename "$PACK_FILE")

OUT_PACK=$TMP_DIR/$OUT_NAME
OUT_NEW_BGYMLS=$TMP_DIR/${OUT_NAME%.pack}

OUT_PACK_DIR=$TMP_DIR/$OUT_NAME-Original/

echo "Unpacking Original .pack file (.pack -> Directory of innereds)"
rm -rf ${OUT_PACK_DIR}
mkdir -p ${OUT_PACK_DIR}
echo "Running ${WILD_BITS_TOOLS} extract_sarc ${OUT_PACK_FILE} ${OUT_PACK_DIR}"
${WILD_BITS_TOOLS} extract_sarc ${PACK_FILE} ${OUT_PACK_DIR}

echo "Packing all bgymls"
rm -rf ${OUT_NEW_BGYMLS}
echo "Running mkdir -p ${OUT_NEW_BGYMLS}"
mkdir -p ${OUT_NEW_BGYMLS}

function process_directory {
	local source="$1"
	local target="$2"
	local original_bgyml="$3"

	mkdir -p "$target"

	for file in "$source"/*; do
		if [ -d "$file" ]; then
			local subdir="${file##*/}"
			process_directory "$file" "$target/$subdir" "$original_bgyml/$subdir"
		elif [ -f "$file" ]; then
			local filename="${file##*/}"
			local outfile=""
			if [[ $filename == *.yml ]]; then
				outfile="${filename%.yml}.bgyml"
				${WILD_BITS_TOOLS} compress_yml "$original_bgyml/$outfile" "$file" "$target/$outfile"
				if [ $? -ne 0 ]; then
				  echo "Error running : ${WILD_BITS_TOOLS} compress_yml $original_bgyml/$outfile $file $target/$outfile"
				fi
			else
				outfile="$filename"
			        cp "$file" "$target/$outfile"
			fi
		fi
	done
}

process_directory $DIFF_FOLDER $OUT_NEW_BGYMLS $OUT_PACK_DIR

echo "Packing .pack file (dir of innnered -> .pack)"
rm $OUT_PACK
echo "Running ${WILD_BITS_TOOLDS} compress_sarc $PACK_FILE $DIFF_FOLDER $OUT_PACK"
#${WILD_BITS_TOOLS} compress_sarc $PACK_FILE $DIFF_FOLDER $OUT_PACK
${WILD_BITS_TOOLS} compress_sarc $PACK_FILE $OUT_NEW_BGYMLS $OUT_PACK

echo "Packing .pack.zs (.pack -> .pack.zs)"
echo "Running ${ZSTD} --compress ${OUT_PACK} -D ${DICT_FILE} -o ${OUT_PACK_ZS} -f"
${ZSTD} --compress ${OUT_PACK} -D ${DICT_FILE} -o ${OUT_PACK_ZS} -f -19

#rm -rf $TMP_DIR
