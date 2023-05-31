#!/bin/bash
#
# This script takes a pack.zs file and extracts data into human readable files that can be used for scraping data, easy modding, ...

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR="${SCRIPT_DIR}/.."
WILD_BITS_TOOLS="${WORK_DIR}/builds/wildbits-tools.exe"

display_help() {
  echo "Usage: $0 [option...] " >&2
  echo
  echo "  -h, --help                 Show help message"

  echo "  -f, --file                 Path to pack.zs file to extract (Required)"
  echo "  -d, --dict                 Path to pack.zsdic generated from romfs (Required)" #TODO: Autogen
  echo "  -o, --outdir               Path to dir to use for extracted files / modding setup (Required)"
  echo "  -z, --zstd                 Path to zstd install (Required)"

  echo "  -x, --clear                Clear state before starting"
  echo
  echo "Example: $0 -f Weapon_Sword_166.pack.zs -d Pack/pack.zsdic -o modding-setup/ -x"
}

clear_data() {
  echo "Clearing outdir: ${OUT_DIR}"
  rm -rf ${OUT_DIR}
  mkdir -p ${OUT_DIR}
}

while getopts ":hf:d:o:z:x" opt; do
  case ${opt} in
    h|--help )
      display_help
      exit 0
      ;;
    f|--file )
      PACK_ZS_FILE=$OPTARG
      ;;
    d|--dict )
      DICT_FILE=$OPTARG
      ;;
    o|--outdir )
      OUT_DIR=$OPTARG
      ;;
    z|--zstd )
      ZSTD=$OPTARG
      ;;
    x|--clear )
      clear_data
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
if [[ -z "${PACK_ZS_FILE}" || -z ${DICT_FILE} || -z "${OUT_DIR}" || -z "${ZSTD}" ]]; then
  echo "Missing required argument: --file or --dict or --oudir or --zstd" 1>&2
  display_help
  exit 1
fi

#TODO: Check files of correct format

TMP_DIR="${WORK_DIR}/tmp/"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

OUT_NAME=$(basename "$PACK_ZS_FILE")
OUT_NAME=${OUT_NAME%.pack.zs}

OUT_PACK_FILE="$OUT_DIR/$OUT_NAME.pack"
OUT_PACK_DIR=$TMP_DIR/$OUT_NAME/
OUT_MOD_DIR=$OUT_DIR/$OUT_NAME/

echo "Unpacking .pack.zs (.pack.zs -> .pack)"
echo "Running ${ZSTD} --decompress ${PACK_ZS_FILE} -D ${DICT_FILE} -o ${OUT_PACK_FILE} -f"
${ZSTD} --decompress ${PACK_ZS_FILE} -D ${DICT_FILE} -o ${OUT_PACK_FILE} -f

echo "Unpacking .pack file (.pack -> Directory of innereds)"
rm -rf ${OUT_PACK_DIR}
mkdir -p ${OUT_PACK_DIR}
echo "Running ${WILD_BITS_TOOLS} extract_sarc ${OUT_PACK_FILE} ${OUT_PACK_DIR}"
${WILD_BITS_TOOLS} extract_sarc ${OUT_PACK_FILE} ${OUT_PACK_DIR}

echo "Unpacking all bgymls"
rm -rf ${OUT_MOD_DIR}
echo "Running mkdir -p ${OUT_MOD_DIR}"
mkdir -p ${OUT_MOD_DIR}

function process_directory {
	local source="$1"
	local target="$2"

	mkdir -p "$target"

	for file in "$source"/*; do
		if [ -d "$file" ]; then
			local subdir="${file##*/}"
			process_directory "$file" "$target/$subdir"
		elif [ -f "$file" ]; then
			local filename="${file##*/}"
			local outfile=""
			if [[ $filename == *.bgyml ]]; then
				outfile="${filename%.bgyml}.yml"
				${WILD_BITS_TOOLS} extract_yml "$file" "$target/$outfile"
				if [ $? -ne 0 ]; then
				  echo "Error running : ${WILD_BITS_TOOLS} extract_yml $file $target/$outfile"
				fi
			else
				outfile="$filename"
			        cp "$file" "$target/$outfile"
			fi
		fi
	done
}

process_directory $OUT_PACK_DIR $OUT_MOD_DIR

#rm -rf $TMP_DIR
