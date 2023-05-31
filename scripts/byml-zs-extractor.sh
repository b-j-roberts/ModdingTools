#!/bin/bash
#
# This script takes a .rstbl.byml.zs file and extracts data into human readable files that can be used for scraping data, easy modding, ...

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR="${SCRIPT_DIR}/.."
WILD_BITS_TOOLS="${WORK_DIR}/builds/wildbits-tools.exe"

display_help() {
  echo "Usage: $0 [option...] " >&2
  echo
  echo "  -h, --help                 Show help message"

  echo "  -f, --file                 Path to .rstbl.byml.zs file to extract (Required)"
  echo "  -d, --dict                 Path to zs.zsdic generated from romfs (Required)" #TODO: Autogen
  echo "  -o, --outdir               Path to dir to use for extracted files / modding setup (Required)"
  echo "  -z, --zstd                 Path to zstd install (Required)"

  echo
  echo "Example: $0 -f PouchActorInfo.Product.100.rstbl.byml.zs -d Pack/zs.zsdic -o modding-setup/"
}

#TODO: Clean option?

while getopts ":hf:d:o:z:" opt; do
  case ${opt} in
    h|--help )
      display_help
      exit 0
      ;;
    f|--file )
      BYML_ZS_FILE=$OPTARG
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

mkdir -p $OUT_DIR

# Check if required arguments are present
if [[ -z "${BYML_ZS_FILE}" || -z ${DICT_FILE} || -z "${OUT_DIR}" || -z "${ZSTD}" ]]; then
  echo "Missing required argument: --file or --dict or --oudir or --zstd" 1>&2
  display_help
  exit 1
fi

#TODO: Check files of correct format

TMP_DIR="${WORK_DIR}/tmp/"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

OUT_NAME=$(basename "$BYML_ZS_FILE")
OUT_NAME=${OUT_NAME%.byml.zs}

OUT_BYML_FILE="$TMP_DIR/$OUT_NAME.byml"
OUT_YML_FILE="$OUT_DIR/$OUT_NAME.yml"

echo "Unpacking .byml.zs (.byml.zs -> .byml)"
echo "Running ${ZSTD} --decompress ${BYML_ZS_FILE} -D ${DICT_FILE} -o ${OUT_BYML_FILE} -f"
${ZSTD} --decompress ${BYML_ZS_FILE} -D ${DICT_FILE} -o ${OUT_BYML_FILE} -f

echo "Unpacking .byml file (.byml -> .yml)"
rm -rf ${OUT_YML_FILE}
echo "Running ${WILD_BITS_TOOLS} extract_yml ${OUT_BYML_FILE} ${OUT_YML_FILE}"
${WILD_BITS_TOOLS} extract_yml ${OUT_BYML_FILE} ${OUT_YML_FILE}

cp $BYML_ZS_FILE $OUT_DIR

#rm -rf $TMP_DIR
