#!/bin/bash
#
# This script takes a yml file and compresses into byml.zs file

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR="${SCRIPT_DIR}/.."
WILD_BITS_TOOLS="${WORK_DIR}/builds/wildbits-tools.exe"

display_help() {
  echo "Usage: $0 [option...] " >&2
  echo
  echo "  -h, --help                 Show help message"

  echo "  -b, --byml                 Path to base byml zs file ( input to byml-zs-extract.sh ) (Required)"
  echo "  -f, --file                 Path to yml file ( From byml-zs-extract.sh ) (Required)"
  echo "  -d, --dict                 Path to zs.zsdic generated from romfs (Required)" #TODO: Autogen
  echo "  -o, --out                  Path to output byml.zs to use for mod (Required)" #TODO: Use based on passed file?
  echo "  -z, --zstd                 Path to zstd install (Required)"

  echo
  echo "Example: $0 -f PouchActorInfo.Product.100.rstbl.yml -d Pack/zs.zsdic -o PouchActorInfo.Product.100.rstbl.byml.zs"
}

while getopts ":hb:f:d:o:z:" opt; do
  case ${opt} in
    h|--help )
      display_help
      exit 0
      ;;
    b|--byml )
      BYML_ZS_FILE=$OPTARG
      ;;
    f|--file )
      YML_FILE=$OPTARG
      ;;
    d|--dict )
      DICT_FILE=$OPTARG
      ;;
    o|--out )
      OUT_BYML_ZS=$OPTARG
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
if [[ -z "${BYML_ZS_FILE}" || -z "${YML_FILE}" || -z ${DICT_FILE} || -z "${OUT_BYML_ZS}" || -z "${ZSTD}" ]]; then
  echo "Missing required argument: --byml or --file or --dict or --out or --zstd" 1>&2
  display_help
  exit 1
fi

#TODO: Check files of correct format

TMP_DIR="${WORK_DIR}/tmp/"
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

OUT_NAME=$(basename "$YML_FILE")
OUT_NAME=${OUT_NAME%.yml}

BYML_FILE="$TMP_DIR/$OUT_NAME.original.byml"
OUT_BYML="$TMP_DIR/$OUT_NAME.byml"

echo "Unzipping original byml.zs (.byml.zs -> .byml)"
echo "Running ${ZSTD} --decompress ${BYML_ZS_FILE} -D ${DICT_FILE} -o ${BYML_FILE} -f"
${ZSTD} --decompress ${BYML_ZS_FILE} -D ${DICT_FILE} -o ${BYML_FILE} -f

echo "Packing byml (.yml -> .byml)"
rm ${OUT_BYML}
echo "${WILD_BITS_TOOLS} compress_yml $YML_FILE $OUT_BYML"
${WILD_BITS_TOOLS} compress_yml $BYML_FILE $YML_FILE $OUT_BYML

echo "Packing .byml.zs (.byml -> .byml.zs)"
echo "${ZSTD} --compress ${OUT_BYML} -D ${DICT_FILE} -o ${OUT_BYML_ZS} -f"
${ZSTD} --compress ${OUT_BYML} -D ${DICT_FILE} -o ${OUT_BYML_ZS} -f -19

#rm -rf $TMP_DIR
