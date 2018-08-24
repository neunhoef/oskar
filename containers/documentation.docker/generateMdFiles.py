#!/usr/bin/env python3

# Sample call in build documentatin script
# #echo " - generating MD-Filedds"
# python3 ${ARANGO_SOURCE}/Documentation/Scripts/generateMdFiles.py \
#        "${book_name}" \
#        "$ARANGO_SOURCE" \
#        "$ARANGO_BUILD_DOC_PRE"
#
#
#    Args:
#    book                          - book name
#    srcDir                        - arango source source
#    outDir                        - out directory
#    fileFilter (optional)         - filter re
#    blockFilter (optional)        - block filter re?!?!a
#
#   needs allComments
#
#   TODO
#   - add path to examples
#   - kill global state
#
#

### module import
import sys
import re
import os
import json
import io
import shutil
import types

from enum import Enum, unique
from pprint import pprint as PP
from pprint import pformat as PF

### set up of logging #########################################################
import logging

logger = logging.getLogger("gmdf")
logger.setLevel(logging.DEBUG)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

#formatter = logging.Formatter('%(asctime)s-%(name)s:%(lineno)d-%(levelname)s - %(message)s',  datefmt='%H:%M:%S')
formatter = logging.Formatter('%(name)s %(lineno)4d %(levelname)6s-> %(message)s',  datefmt='%H:%M:%S')
ch.setFormatter(formatter)
logger.addHandler(ch)

def log_multi(level, msg, *args, **kwargs):
    [ logger.log(level, x, *args, **kwargs) for x in msg.split('\n') ]

### set up of logging - END ####################################################

### main #######################################################################
def main():
    if len(sys.argv) < 2:
        logger.info("usage: book arango-source output-directory swaggerJson [filter]")
        sys.exit(1)

    conf = Config(sys.argv[1], sys.argv[2], sys.argv[3])
    log_multi(logging.INFO, str(conf))

    # #TODO add to conf if required
    # if len(sys.argv) > 5 and sys.argv[5].strip() != '':
    #     logger.info("filtering " + sys.argv[4])
    #     fileFilter = re.compile(sys.argv[5])
    # if len(sys.argv) > 6 and sys.argv[6].strip() != '':
    #     logger.info("filtering Docublocks: " + sys.argv[5])
    #     blockFilter = re.compile(sys.argv[6])
    # ## end

    swagger=None
    with open(conf.swaggerJson, 'r', encoding='utf-8', newline=None) as f:
        swagger=json.load(f)

    block_reader = DocuBlockReader()
    blocks = block_reader.parse(conf.allComments, swagger)
    blocks.replace_code_in_blocks()

    block_load_all(conf.allComments, swagger) # FIXME "allComments.txt"

    loadProgramOptionBlocks() # FIXME

    logger.info("loaded {} / {} docu blocks".format(len(dokuBlocks[0]), len(dokuBlocks[1])))

    # walk over .md files and replace blocks
    walk_on_files(conf)

    return 0
### main - END #################################################################

### helper #####################################################################
def mkdir_recursive(ipath):
    """ creates a directory of arbitrary depth"""
    path = path_abs_norm(ipath)
    os.makedirs(path, exist_ok=True)

def path_abs_norm(path):
    """ returns absolute normalized path"""
    return os.path.normpath(os.path.abspath(path))

class Config():
    def __init__(self,book, src, out):
        self.book = book
        self.src = path_abs_norm(src)
        self.out =  path_abs_norm(out)

        self.book_src = os.path.join(self.src ,"Documentation","Books", self.book)
        self.book_out = os.path.join(self.out , self.book)
        self.allComments = os.path.join(self.src, "Documentation", "Books", "allComments.txt")
        self.swaggerJson = os.path.join(self.src, "js","apps","system","_admin","aardvark","APP","api-docs.json")

    def __str__(self):
        return """
book       : {book}
src        : {src}
out        : {out}
book_src   : {book_src}
allComments: {allComments}
swaggerJson: {swaggerJson}
""".format(**(self.__dict__))
### helper - END ###############################################################

## reading of DocuBlocks ######################################################
@unique
class BlockType(Enum):
    PLAIN  = 1 #auto()
    INLINE = 2 #auto()


class DocuBlocks():
    #TODO rename allComments.txt - to intermeadiate Docublocks
    """ Structure that holds plain and inline docublocks that are found in the allComments.txt files
    """

    def __init__(self, swagger):
        self.plain_blocks = {}
        self.inline_blocks = {}
        self.swagger = swagger

    def add(self, block):
        """ adds a block found by the parser"""
        #self.block_replace_code(block)
        if block.block_type is BlockType.PLAIN:
            self.plain_blocks[block.key]=block
        elif block.block_type is BlockType.INLINE:
            self.inline_blocks[block.key]=block
        else:
            print (repr(block))
            raise ValueError("invalid block type")

    def replace_code_in_blocks(self):
        """ should happen later during add block"""
        PF(self.plain_blocks)
        for _, block in self.plain_blocks.items():
            self.block_replace_code(block)
        for _, block in self.inline_blocks.items():
            self.block_replace_code(block)


    def block_replace_code(self, block):
        """clean up functions that needs to be run on each block"""
        global thisVerb, route, verb ## why does it crash if these variables are not global
                                     ## TODO look for function calls that use global STATE
        #route = ''
        #verb = ''
        #thisVerb = {}

        thisVerb = {}
        foundRest = False
        # first find the header:
        headerMatch = match_RESTHEADER.search(block.content)
        if headerMatch and headerMatch.lastindex > 0:
            foundRest = True
            try:
                (verb,route) =  headerMatch.group(1).split(',')[0].split(' ')
                verb = verb.lower()
            except:
                logger.error("failed to parse header from: " + headerMatch.group(1) + " while analysing " + block.key)
                raise

            try:
                thisVerb = self.swagger['paths'][route][verb]
            except:
                logger.error("failed to locate route in the swagger json: [" + verb + " " + route + "]" + " while analysing " + block.key)
                logger.error(block.content)
                logger.error("Did you forget to run utils/generateSwagger.sh?")
                raise

        for (oneRX, repl) in RX:
            block.content = oneRX.sub(repl, block.content)


        if foundRest:
            rcCode = None
            foundRestBodyParam = False
            foundRestReplyBodyParam = False
            lineR = block.content.split('\n')
            #logger.info(lineR)
            l = len(lineR)
            r = 0
            while (r < l):
                # remove all but the first RESTBODYPARAM:
                if have_RESTBODYPARAM.search(lineR[r]):
                    if foundRestBodyParam:
                        lineR[r] = ''
                    else:
                        lineR[r] = '@RESTDESCRIPTION'
                    foundRestBodyParam = True
                    r+=1
                    while ((len(lineR[r]) == 0) or
                           ((lineR[r][0] != '@') or
                           have_RESTBODYPARAM.search(lineR[r]))):
                        # logger.info("xxx - %d %s" %(len(lineR[r]), lineR[r]))
                        lineR[r] = ''
                        r+=1

                m = match_RESTRETURNCODE.search(lineR[r])
                if m and m.lastindex > 0:
                    rcCode =  m.group(1)

                # remove all but the first RESTREPLYBODY:
                if have_RESTREPLYBODY.search(lineR[r]):
                    if foundRestReplyBodyParam != rcCode:
                        lineR[r] = '@RESTREPLYBODY{' + rcCode + '}\n'
                    else:
                        lineR[r] = ''
                    foundRestReplyBodyParam = rcCode
                    r+=1
                    while (len(lineR[r]) > 1):
                        lineR[r] = ''
                        r+=1
                    m = match_RESTRETURNCODE.search(lineR[r])
                    if m and m.lastindex > 0:
                        rcCode =  m.group(1)

                # remove all RESTSTRUCTS - they're referenced anyways:
                if have_RESTSTRUCT.search(lineR[r]):
                    while (len(lineR[r]) > 1):
                        lineR[r] = ''
                        r+=1
                r+=1
            block.content = "\n".join(lineR)
        #logger.info("x" * 70)
        #logger.info(block.content)
        #log_multi(logging.ERROR, PF({ "thisVerb" : thisVerb, "verb" : verb, "route" : route}))
        try:
            block.content = SIMPLE_RX.sub(lambda match : block_simple_repl(match, self.swagger, thisVerb), block.content)
        except Exception as e:
            logger.error("While working on: [" + verb + " " + route + "]" + " while analysing " + block.key)
            logger.error(str(e))
            logger.error("Did you forget to run utils/generateSwagger.sh?")
            raise e


        for (oneRX, repl) in RX2:
            block.content = oneRX.sub(repl, block.content)

        block.content = remove_MULTICR.sub("\n\n", block.content)
        #logger.info(block.content)
        return block.content



class DocuBLock():
    """description of a single DocuBlock"""
    def __init__(self,btype):
        self.block_type = btype  # plain or inline
        self.content = ""        # textual content of the block
        self.key = None          # block key or name

class DocuBlockReader():
    def __init__(self):
        self.blocks = None

    def parse(self, filename, swagger):
               # file to read the blocks from
        self.blocks = DocuBlocks(swagger);    # stucture that the found blocks are added to and
                                       # that is returned when the parse has finished
        """ Parses the text document that contains the DocuBlocks.

            A state machine is used here, as long as the block is
            None we search for the start of a new block. Otherwise
            we are within a block and add to the block or close it.
            When the block is closed we begin to search for a new block.
        """

        with open(filename, "r", encoding="utf-8", newline=None) as f:
            block = None
            for line in f:
                block = self.handle_line(line, block)

            if block != None:
                raise ValueError("we are inside and open block!!!")
        return self.blocks


    def handle_line(self, line, block):
        if not block:
            block = self.handle_line_start(line)
        else:
            block = self.handle_line_follow(line, block)
        return block


    def handle_line_start(self, line):
        if ("@startDocuBlock" in line):
            if "@startDocuBlockInline" in line:
                block = DocuBLock(BlockType.PLAIN)
            else:
                block = DocuBLock(BlockType.INLINE)

            #logger.debug("start: " + str(block))
            try:
                block.key = SEARCH_START.search(line).group(1).strip()
            except:
                logger.error("failed to read startDocuBlock: [" + line + "]")
                exit(1)

            #logger.debug("starting block with key {}".format(block.key))
            return block
        return None

    def handle_line_follow(self, line,block):
        if '@endDocuBlock' in line:
            #logger.debug("complete: " + str(block))
            #logger.debug("complete: " + str(block.key))
            #logger.debug("complete: " + str(block.block_type))
            self.blocks.add(block)
            #logger.info("ending block with key {}".format(block.key))
            return None
        # apppend to content and do not change state
        block.content += line
        return block

## reading of DocuBlocks - END  ###############################################


## replace blocks in .md-files ################################################

#OK
def walk_on_files(conf):
    """ walk over source tree and skip files and calculate output path for
        files that are not skipped
    """

    global fileFilter #do we want to modify this? why global

    count = 0
    skipped = 0

    #logger.info("walk on files inDirPath: " + conf.book_src)
    for root, dirs, files in os.walk(conf.book_src):
        for file in files:

            in_full_path=os.path.join(root,file)
            in_rel_path=os.path.relpath(in_full_path, conf.book_src)
            out_full_path = os.path.join(conf.book_out, in_rel_path)


            if file.endswith(".md") and not file.endswith("SUMMARY.md"):
                count += 1
                if fileFilter != None:
                    if fileFilter.match(in_full_path) == None:
                        skipped += 1
                        continue;
                ## what are those 2 functions doing
                mkdir_recursive(os.path.dirname(out_full_path)) #create dir for output file
                walk_find_start_code(in_full_path, out_full_path, conf)
    logger.info( "Processed %d files, skipped %d" % (count, skipped))

#OK - TODO - rename to something useful
def walk_find_start_code(in_full, out_full, conf):
    """ replace dcoublocks and images
    """
    baseInPath = conf.book_src

    textFile = None
    with open(in_full, "r", encoding="utf-8", newline=None) as fd:
        textFile = fd.read()

    #logger.debug(textFile)
    matches = re.findall(r'@startDocuBlockInline\s*(\w+)', textFile)
    for match in matches:
        #logger.debug(in_full + " " + match)
        textFile = walk_replace_text_inline(textFile, in_full, match)

    matches = re.findall(r'@startDocuBlock\s*(\w+)', textFile)
    for match in matches:
        #logger.debug(in_full + " " + match)
        textFile = walk_replace_text(textFile, in_full, match)

    try:
        textFile = walk_replace_code_full_file(textFile)
    except Exception as e:
        logger.error("while parsing :      "  + in_full)
        logger.error(textFile)
        raise e

    re_images = re.compile(r".*\!\[([\d\s\w\/\. ()-]*)\]\(([\d\s\w\/\.-]*)\).*")
    textFile = re.sub(re_images
                     ,lambda match: walk_handle_images(match.groups()[0]
                                                 ,match.groups()[1]
                                                 ,conf
                                                 ,in_full
                                                 ,out_full
                                                 )
                     ,textFile
                     )

    with open(out_full, "w", encoding="utf-8", newline="") as fd:
        fd.write(textFile)

    return 0

def walk_replace_text_inline(text, pathOfFile, searchText):
  ''' inserts docublocks into md '''
  global dokuBlocks
  if not searchText in dokuBlocks[1]:
      logger.error("Failed to locate the inline docublock '" + searchText + "' for replacing it into the file '" + pathOfFile + "'\n have: ")
      logger.error("%s" %(dokuBlocks[1].keys()))
      logger.error('*' * 80)
      logger.error(text)
      logger.error("Failed to locate the inline docublock '" + searchText + "' for replacing it into the file '" + pathOfFile + "' For details scroll up!")
      exit(1)
  rePattern = r'(?s)\s*@startDocuBlockInline\s+'+ searchText +'\s.*?@endDocuBlock\s' + searchText
  # (?s) is equivalent to flags=re.DOTALL but works in Python 2.6
  match = re.search(rePattern, text)

  if (match == None):
      logger.error("failed to match with '" + rePattern + "' for " + searchText + " in file " + pathOfFile + " in: \n" + text)
      exit(1)

  subtext = match.group(0)
  if (len(re.findall('@startDocuBlock', subtext)) > 1):
      logger.error("failed to snap with '" + rePattern + "' on end docublock for " + searchText + " in " + pathOfFile + " our match is:\n" + subtext)
      exit(1)

  return re.sub(rePattern, dokuBlocks[1][searchText], text)

def walk_replace_text(text, pathOfFile, searchText):
  ''' inserts docublocks into md '''
  #logger.info('7'*80)
  global dokuBlocks
  if not searchText in dokuBlocks[0]:
      logger.error("Failed to locate the docublock '" + searchText + "' for replacing it into the file '" +pathOfFile + "'\n have:")
      logger.error(dokuBlocks[0].keys())
      logger.error('*' * 80)
      logger.error(text)
      logger.error("Failed to locate the docublock '" + searchText + "' for replacing it into the file '" +pathOfFile + "' For details scroll up!")
      exit(1)
  #logger.info('7'*80)
  #logger.info(dokuBlocks[0][searchText])
  #logger.info('7'*80)
  rc= re.sub("@startDocuBlock\s+"+ searchText + "(?:\s+|$)", dokuBlocks[0][searchText], text)
  return rc

#OK
def walk_handle_images(image_title, image_link, conf, in_full, out_full):
    """ copy images from source to pp dir, copy book external images
        to <book>/assets and update image links accordingly.
    """
    src_image = path_abs_norm(os.path.join(os.path.dirname(in_full), image_link))
    out_image = path_abs_norm(os.path.join(os.path.dirname(out_full), image_link))

    assets = os.path.join(conf.book_out, "assets")

    #for images that are not within this book
    if os.path.commonprefix([src_image, conf.book_src]) != conf.book_src:

        ## the file will end up in out/<bookname>/assets
        # get image name
        out_image_name = os.path.basename(image_link)
        # append name to assets
        out_image = os.path.join(assets, out_image_name)

        # get path of the current document
        out_full_dir = os.path.dirname(out_full)
        # get the relative location of the assets dir to the current document
        out_image_rel_dir = os.path.relpath(assets, out_full_dir)
        # append the image name
        image_link = os.path.join(out_image_rel_dir,out_image_name)

    outdir = os.path.dirname(out_image)
    if not os.path.exists(outdir):
        mkdir_recursive(outdir)

    #logger.debug(src_image + " -> "+ out_image)
    if not os.path.exists(out_image):
        shutil.copy(src_image, out_image)

    #logger.debug("out_image:    " + out_image)
    #logger.debug("image_link:   " + image_link)
    return str('![' + image_title + '](' + image_link + ')')

## replace blocks in .md-files - END ##########################################










#######################################################################################################
#######################################################################################################
#######################################################################################################
#######################################################################################################

fileFilter = None
blockFilter = None
dokuBlocks = [{},{}]
thisVerb = {}

route = ''
verb = '' #    #TODO add path to examples'

defLen = len('#/definitions/')

removeTrailingBR = re.compile("<br>$")
removeLeadingBR = re.compile("^<br>")
removeDoubleLF = re.compile("\n\n")
removeLF = re.compile("\n")





SIMPLE_RX = re.compile(
r'''
\\|                                 # the backslash...
@RESTDESCRIPTION|                   # -> <empty>
@RESTURLPARAMETERS|                 # -> \n**Path Parameters**\n
@RESTQUERYPARAMETERS|               # -> \n**Query Parameters**\n
@RESTHEADERPARAMETERS|              # -> \n**Header Parameters**\n
@RESTBODYPARAM|                     # empty now, comes with the post body -> call post body param
@RESTRETURNCODES|                   # -> \n**Return Codes**\n
@PARAMS|                            # -> \n**Parameters**\n
@RESTPARAMS|                        # -> <empty>
@RESTURLPARAMS|                     # -> <empty>
@RESTQUERYPARAMS|                   # -> <empty>
@PARAM|                             # -> @RESTPARAM
@RESTURLPARAM|                      # -> @RESTPARAM
@RESTQUERYPARAM|                    # -> @RESTPARAM
@RESTHEADERPARAM|                   # -> @RESTPARAM
@EXAMPLES|                          # -> \n**Examples**\n
@RESTPARAMETERS|                    # -> <empty>
@RESTREPLYBODY\{(.*)\}              # -> call body function
''', re.X)



###### validataion dict ########################################################
def noValidation(thisVerb):
    pass

def validatePathParameters(thisVerb):
    # logger.info(thisVerb)
    for nParam in range(0, len(thisVerb['parameters'])):
        if thisVerb['parameters'][nParam]['in'] == 'path':
            break
    else:
        raise Exception("@RESTPATHPARAMETERS found in Swagger data without any parameter following in %s " % json.dumps(thisVerb, indent=4, separators=(', ',': '), sort_keys=True))

def validateQueryParams(thisVerb):
    # logger.info(thisVerb)
    for nParam in range(0, len(thisVerb['parameters'])):
        if thisVerb['parameters'][nParam]['in'] == 'query':
            break
    else:
        raise Exception("@RESTQUERYPARAMETERS found in Swagger data without any parameter following in %s " % json.dumps(thisVerb, indent=4, separators=(', ',': '), sort_keys=True))

def validateHeaderParams(thisVerb):
    # logger.info(thisVerb)
    for nParam in range(0, len(thisVerb['parameters'])):
        if thisVerb['parameters'][nParam]['in'] == 'header':
            break
    else:
        raise Exception("@RESTHEADERPARAMETERS found in Swagger data without any parameter following in %s " % json.dumps(thisVerb, indent=4, separators=(', ',': '), sort_keys=True))

def validateReturnCodes(thisVerb):
    # logger.info(thisVerb)
    for nParam in range(0, len(thisVerb['responses'])):
        if len(thisVerb['responses'].keys()) != 0:
            break
    else:
        raise Exception("@RESTRETURNCODES found in Swagger data without any documented returncodes %s " % json.dumps(thisVerb, indent=4, separators=(', ',': '), sort_keys=True))

SIMPL_REPL_VALIDATE_DICT = {
    "@RESTDESCRIPTION"      : noValidation,
    "@RESTURLPARAMETERS"    : validatePathParameters,
    "@RESTQUERYPARAMETERS"  : validateQueryParams,
    "@RESTHEADERPARAMETERS" : validateHeaderParams,
    "@RESTRETURNCODES"      : validateReturnCodes,
    "@RESTURLPARAMS"        : validatePathParameters,
    "@EXAMPLES"             : noValidation
}

###### validataion dict - END ########################################################

###### simple dict  ########################################################
def getRestDescription(swagger, thisVerb, param):
    #logger.debug("RESTDESCRIPTION")
    if thisVerb['description']:
        #logger.error(thisVerb['description'])
        return RX3[0].sub(RX3[1], thisVerb['description'])
    else:
        #logger.debug("rest description empty")
        return ""

def getRestReplyBodyParam(swagger, thisVerb, param):
    rc = "\n**Response Body**\n"

    try:
        rc += unwrapPostJson(swagger, getReference(swagger, thisVerb['responses'][param]['schema'], route, verb), 0)
    except Exception:
        logger.error("failed to search " + param + " in: ")
        logger.error(json.dumps(thisVerb, indent=4, separators=(', ',': '), sort_keys=True))
        raise
    return rc + "\n"

REST_REPLACEMENT_DICT = {
    "\\"                    : "\\\\",
    "@RESTDESCRIPTION"      : getRestDescription,
    "@RESTURLPARAMETERS"    : "\n**Path Parameters**\n",
    "@RESTQUERYPARAMETERS"  : "\n**Query Parameters**\n",
    "@RESTHEADERPARAMETERS" : "\n**Header Parameters**\n",
    "@RESTRETURNCODES"      : "\n**Return Codes**\n",
    "@PARAMS"               : "\n**Parameters**\n",
    "@RESTPARAMS"           : "",
    "@RESTURLPARAMS"        : "\n**Path Parameters**\n",
    "@RESTQUERYPARAMS"      : "\n**Query Parameters**\n",
    "@RESTBODYPARAM"        : "",
    "@RESTREPLYBODY"        : getRestReplyBodyParam,
    "@RESTQUERYPARAM"       : "@RESTPARAM",
    "@RESTURLPARAM"         : "@RESTPARAM",
    "@PARAM"                : "@RESTPARAM",
    "@RESTHEADERPARAM"      : "@RESTPARAM",
    "@EXAMPLES"             : "\n**Examples**\n",
    "@RESTPARAMETERS"       : ""
}
###### simple dict - END ########################################################

RX = [
    ### match -> replace
    # comments -> nothing
    (re.compile(r"<!--(\s*.+\s)-->"), ""),

    # <br > newline -> newline
    (re.compile(r"<br />\n"), "\n"),

    # multi line bullet lists should become one
    (re.compile(r"\n\n-"), "\n-"),

    #HTTP API changing code
    # unwrap multi-line-briefs: (up to 3 lines supported by now ;-)
    (re.compile(r"@brief(.+)\n(.+)\n(.+)\n\n"), r"@brief\g<1> \g<2> \g<3>\n\n"),
    (re.compile(r"@brief(.+)\n(.+)\n\n"), r"@brief\g<1> \g<2>\n\n"),

    # if there is an @brief above a RESTHEADER, swap the sequence
    (re.compile(r"@brief(.+\n*)\n@RESTHEADER{([#\s\w\/\_{}-]*),([\s\w-]*)}"), r"###\g<3>\n\g<1>\n\n`\g<2>`"),

    # else simply put it into the text
    (re.compile(r"@brief(.+)"), r"\g<1>"),

    # Format error codes from errors.dat
    (re.compile(r"#####+\n"), r""),
    (re.compile(r"## (.+\n\n)## (.+\n)"), r"## \g<1>\g<2>"),
    #  (re.compile(r"- (\w+):\s*@LIT{(.+)}"), r"\n*\g<1>* - **\g<2>**:"),
    (re.compile(r"(.+),(\d+),\"(.+)\",\"(.+)\""), r'\n* <a name="\g<1>"></a>**\g<2>** - **\g<1>**<br>\n  \g<4>'),

    (re.compile(r"TODOSWAGGER.*"),r"")
    ]


RX2 = [
    # parameters - extract their type and whether mandatory or not.
    (re.compile(r"@RESTPARAM{(\s*[\w\-]*)\s*,\s*([\w\_\|-]*)\s*,\s*(required|optional)}"), r"* *\g<1>* (\g<3>):"),
    (re.compile(r"@RESTALLBODYPARAM{(\s*[\w\-]*)\s*,\s*([\w\_\|-]*)\s*,\s*(required|optional)}"), r"\n**Request Body** (\g<3>)\n\n"),
    (re.compile(r"@RESTRETURNCODE{(.*)}"), r"* *\g<1>*:")
]

RX3 = (re.compile(r'\*\*Example:\*\*((?:.|\n)*?)</code></pre>'), r"")

match_RESTHEADER = re.compile(r"@RESTHEADER\{(.*)\}")
match_RESTRETURNCODE = re.compile(r"@RESTRETURNCODE\{(.*)\}")
have_RESTBODYPARAM = re.compile(r"@RESTBODYPARAM|@RESTDESCRIPTION")
have_RESTREPLYBODY = re.compile(r"@RESTREPLYBODY")
have_RESTSTRUCT = re.compile(r"@RESTSTRUCT")
remove_MULTICR = re.compile(r'\n\n\n*')

RXUnEscapeMDInLinks = re.compile("\\\\_")
def setAnchor(param):
    unescapedParam = RXUnEscapeMDInLinks.sub("_", param)
    return "<a name=\"" + unescapedParam + "\">#</a>"

RXFinal = [
    (re.compile(r"@anchor (.*)"), setAnchor),
]
thisBlock = ""
thisBlockName = ""
thisBlockType = 0


SEARCH_START = re.compile(r" *start[0-9a-zA-Z]*\s\s*([0-9a-zA-Z_ ]*)\s*$")



def walk_replace_code_full_file(lines):
    for (oneRX, repl) in RXFinal:
        lines = oneRX.sub(repl, lines)
    return lines

def brTrim(text):
    return removeLeadingBR.sub("", removeTrailingBR.sub("", text.strip(' ')))


def getReference(swagger, name, source, verb):
    try:
        ref = name['$ref'][defLen:]
    except Exception as x:
        logger.error("No reference in: " + name)
        raise
    if not ref in swagger['definitions']:
        fn = ''
        if verb:
            fn = swagger['paths'][route][verb]['x-filename']
        else:
            fn = swagger['definitions'][source]['x-filename']
        logger.error(json.dumps(swagger['definitions'], indent=4, separators=(', ',': '), sort_keys=True))
        raise Exception("invalid reference: " + ref + " in " + fn)
    return ref


def TrimThisParam(text, indent):
    text = text.rstrip('\n').lstrip('\n')
    text = removeDoubleLF.sub("\n", text)
    if (indent > 0):
        indent = (indent + 2) # align the text right of the list...
    return removeLF.sub("\n" + ' ' * indent, text)

def unwrapPostJson(swagger, reference, layer):
    swaggerDataTypes = ["number", "integer", "string", "boolean", "array", "object"]
    ####
    # logger.error("xx" * layer + reference)
    rc = ''
    if not 'properties' in swagger['definitions'][reference]:
        if 'items' in swagger['definitions'][reference]:
            if swagger['definitions'][reference]['type'] == 'array':
                rc += '[\n'
            subStructRef = getReference(swagger, swagger['definitions'][reference]['items'], reference, None)
            rc += unwrapPostJson(swagger, subStructRef, layer + 1)
            if swagger['definitions'][reference]['type'] == 'array':
                rc += ']\n'
    else:
        for param in swagger['definitions'][reference]['properties'].keys():
            thisParam = swagger['definitions'][reference]['properties'][param]
            required = ('required' in swagger['definitions'][reference] and
                        param in swagger['definitions'][reference]['required'])

            # logger.error(thisParam)
            if '$ref' in thisParam:
                subStructRef = getReference(swagger, thisParam, reference, None)

                rc += '  ' * layer + "- **" + param + "**:\n"
                ####
                # logger.error("yy" * layer + param)
                rc += unwrapPostJson(swagger, subStructRef, layer + 1)

            elif thisParam['type'] == 'object':
                rc += '  ' * layer + "- **" + param + "**: " + TrimThisParam(brTrim(thisParam['description']), layer) + "\n"
            elif thisParam['type'] == 'array':
                rc += '  ' * layer + "- **" + param + "**"
                trySubStruct = False
                lf=""
                ####
                # logger.error("zz" * layer + param)
                if 'type' in thisParam['items']:
                    rc += " (" + thisParam['items']['type']  + ")"
                    lf="\n"
                else:
                    if len(thisParam['items']) == 0:
                        rc += " (anonymous json object)"
                        lf="\n"
                    else:
                        trySubStruct = True
                rc += ": " + TrimThisParam(brTrim(thisParam['description']), layer) + lf
                if trySubStruct:
                    subStructRef = None
                    try:
                        subStructRef = getReference(swagger, thisParam['items'], reference, None)
                    except Exception as e:
                        logger.error("while analyzing: " + param)
                        logger.error(thisParam)
                        raise e
                    rc += "\n" + unwrapPostJson(swagger, subStructRef, layer + 1)
            else:
                if thisParam['type'] not in swaggerDataTypes:
                    logger.error("while analyzing: " + param)
                    logger.error(thisParam['type'] + " is not a valid swagger datatype; supported ones: " + str(swaggerDataTypes))
                    raise Exception("invalid swagger type")
                rc += '  ' * layer + "- **" + param + "**: " + TrimThisParam(thisParam['description'], layer) + '\n'
    return rc



def exectue_if_function(fun, *args, **kwargs):
    if type(fun) == types.FunctionType:
        logging.info("execute function")
        return fun(*args, **kwargs)
    else:
        return fun


def block_simple_repl(match, swagger, thisVerb):
    m = match.group(0)
    #logger.info('xxxxx [%s]' % m)
    #log_multi(logging.ERROR, 'xxxxx [%s]' % thisVerb)

    validation_function = SIMPL_REPL_VALIDATE_DICT.get(m, None)
    if validation_function:
        validation_function(thisVerb)


    rest_replacement = REST_REPLACEMENT_DICT.get(m, None)
    if rest_replacement:
        return exectue_if_function(rest_replacement, swagger, thisVerb, None)
    else:
        pos = m.find('{')
        if pos > 0:
            newMatch = m[:pos]
            param = m[pos + 1 :].rstrip(' }')

            new_rest_replacement = REST_REPLACEMENT_DICT.get(newMatch, None)
            if new_rest_replacement == None:
                raise Exception("failed to find regex while searching for: " + newMatch + " extracted from: " + m)
            else:
                return exectue_if_function(new_rest_replacement, swagger, thisVerb, param)



#################################################################################
####### to be deleted ###########################################################
#################################################################################
@unique
class DocuSearchState(Enum):
    START = 0
    END = 1


def readStartLine(line):
    global thisBlockName, thisBlockType, thisBlock, dokuBlocks
    if ("@startDocuBlock" in line):
        if "@startDocuBlockInline" in line:
            thisBlockType = 1
        else:
            thisBlockType = 0
        try:
            thisBlockName = SEARCH_START.search(line).group(1).strip()
        except:
            logger.error("failed to read startDocuBlock: [" + line + "]")
            exit(1)
        dokuBlocks[thisBlockType][thisBlockName] = ""
        return DocuSearchState.END
    return DocuSearchState.START

def readNextLine(line):
    global thisBlockName, thisBlockType, thisBlock, dokuBlocks
    if '@endDocuBlock' in line:
        return DocuSearchState.START
    dokuBlocks[thisBlockType][thisBlockName] += line
    #logger.info("reading " + thisBlockName)
    #logger.info(dokuBlocks[thisBlockType][thisBlockName])
    return DocuSearchState.END

def block_load_all(allComments, swagger):
    state = DocuSearchState.START
    f = io.open(allComments, "r", encoding="utf-8", newline=None)
    count = 0
    for line in f.readlines():
        if state is DocuSearchState.START:
            state = readStartLine(line)
        elif state is DocuSearchState.END:
            state = readNextLine(line)

        #if state == DocuSearchState.START:
        #    logger.info(dokuBlocks[thisBlockType].keys())

    if blockFilter != None:
        remainBlocks= {}
        logger.info("filtering blocks")
        for oneBlock in dokuBlocks[0]:
            if blockFilter.match(oneBlock) != None:
                logger.info("found block %s" % (oneBlock))
                #logger.info(dokuBlocks[0][oneBlock])
                remainBlocks[oneBlock] = dokuBlocks[0][oneBlock]
        dokuBlocks[0] = remainBlocks


    #TODO blocks.add(block)
    for oneBlock in dokuBlocks[0]:
        try:
            #logger.info("processing %s" % oneBlock)
            dokuBlocks[0][oneBlock] = block_replace_code(swagger, dokuBlocks[0][oneBlock], oneBlock)
            #logger.info("6"*80)
            #logger.info(dokuBlocks[0][oneBlock])
            #logger.info("6"*80)
        except:
            logger.error("while parsing :\n"  + oneBlock)
            raise

    for oneBlock in dokuBlocks[1]:
        try:
            dokuBlocks[1][oneBlock] = block_replace_code(swagger, dokuBlocks[1][oneBlock], oneBlock)
        except:
            logger.error("while parsing :\n"  + oneBlock)
            raise
def block_replace_code(swagger, lines, blockName):
    global thisVerb, route, verb
    thisVerb = {}
    foundRest = False
    # first find the header:
    headerMatch = match_RESTHEADER.search(lines)
    if headerMatch and headerMatch.lastindex > 0:
        foundRest = True
        try:
            (verb,route) =  headerMatch.group(1).split(',')[0].split(' ')
            verb = verb.lower()
        except:
            logger.error("failed to parse header from: " + headerMatch.group(1) + " while analysing " + blockName)
            raise

        try:
            thisVerb = swagger['paths'][route][verb]
        except:
            logger.error("failed to locate route in the swagger json: [" + verb + " " + route + "]" + " while analysing " + blockName)
            logger.error(lines)
            logger.error("Did you forget to run utils/generateSwagger.sh?")
            raise

    for (oneRX, repl) in RX:
        lines = oneRX.sub(repl, lines)


    if foundRest:
        rcCode = None
        foundRestBodyParam = False
        foundRestReplyBodyParam = False
        lineR = lines.split('\n')
        #logger.info(lineR)
        l = len(lineR)
        r = 0
        while (r < l):
            # remove all but the first RESTBODYPARAM:
            if have_RESTBODYPARAM.search(lineR[r]):
                if foundRestBodyParam:
                    lineR[r] = ''
                else:
                    lineR[r] = '@RESTDESCRIPTION'
                foundRestBodyParam = True
                r+=1
                while ((len(lineR[r]) == 0) or
                       ((lineR[r][0] != '@') or
                       have_RESTBODYPARAM.search(lineR[r]))):
                    # logger.info("xxx - %d %s" %(len(lineR[r]), lineR[r]))
                    lineR[r] = ''
                    r+=1

            m = match_RESTRETURNCODE.search(lineR[r])
            if m and m.lastindex > 0:
                rcCode =  m.group(1)

            # remove all but the first RESTREPLYBODY:
            if have_RESTREPLYBODY.search(lineR[r]):
                if foundRestReplyBodyParam != rcCode:
                    lineR[r] = '@RESTREPLYBODY{' + rcCode + '}\n'
                else:
                    lineR[r] = ''
                foundRestReplyBodyParam = rcCode
                r+=1
                while (len(lineR[r]) > 1):
                    lineR[r] = ''
                    r+=1
                m = match_RESTRETURNCODE.search(lineR[r])
                if m and m.lastindex > 0:
                    rcCode =  m.group(1)

            # remove all RESTSTRUCTS - they're referenced anyways:
            if have_RESTSTRUCT.search(lineR[r]):
                while (len(lineR[r]) > 1):
                    lineR[r] = ''
                    r+=1
            r+=1
        lines = "\n".join(lineR)
    #logger.info("x" * 70)
    #logger.info(lines)
    try:
        lines = SIMPLE_RX.sub(lambda match : block_simple_repl(match, swagger, thisVerb), lines)
    except Exception as x:
        logger.error("While working on: [" + verb + " " + route + "]" + " while analysing " + blockName)
        logger.error("Did you forget to run utils/generateSwagger.sh?")
        raise x


    for (oneRX, repl) in RX2:
        lines = oneRX.sub(repl, lines)

    lines = remove_MULTICR.sub("\n\n", lines)
    #logger.info(lines)
    return lines

# NOT USED
#def replaceCodeIndex(lines):
#  lines = re.sub(r"<!--(\s*.+\s)-->","", lines)
#  #HTTP API changing code
#  #lines = re.sub(r"@brief(.+)",r"\g<1>", lines)
#  #lines = re.sub(r"@RESTHEADER{([\s\w\/\_{}-]*),([\s\w-]*)}", r"###\g<2>\n`\g<1>`", lines)
#  return lines
#################################################################################
####### to be deleted - end #####################################################
#################################################################################




################################################################################
# Read the docublocks into memory
################################################################################



def loadProgramOptionBlocks():
    from itertools import groupby, chain
    from cgi import escape
    from glob import glob

    global dokuBlocks

    # Allows to test if a group will be empty with hidden options ignored
    def peekIterator(iterable, condition):
        try:
            while True:
                first = next(iterable)
                if condition(first):
                    break
        except StopIteration:
            return None
        return first, chain([first], iterable)

    # Give options a the section name 'global' if they don't have one
    def groupBySection(elem):
        return elem[1]["section"] or 'global'

    # Empty section string means global option, which should appear first
    def sortBySection(elem):
        section = elem[1]["section"]
        if section:
            return (1, section)
        return (0, u'global')

    # Format possible values as unordered list
    def formatList(arr, text=''):
        formatItem = lambda elem: '<li><code>{}</code></li>'.format(elem)
        return '{}<ul>{}</ul>\n'.format(text, '\n'.join(map(formatItem, arr)))

    for programOptionsDump in glob(os.path.normpath('../Examples/*.json')):

        program = os.path.splitext(os.path.basename(programOptionsDump))[0]
        output = []

        # Load program options dump and convert to Python object
        with io.open(programOptionsDump, 'r', encoding='utf-8', newline=None) as fp:
            try:
                optionsRaw = json.load(fp)
            except ValueError as err:
                # invalid JSON
                logger.error("Failed to parse program options json: '" + programOptionsDump + "' - to be used as: '" + program + "' - " + err.message)
                raise err

        # Group and sort by section name, global section first
        for groupName, group in groupby(
                sorted(optionsRaw.items(), key=sortBySection),
                key=groupBySection):

            # Use some trickery to skip hidden options without consuming items from iterator
            groupPeek = peekIterator(group, lambda elem: elem[1]["hidden"] is False)
            if groupPeek is None:
                # Skip empty section to avoid useless headline (all options are hidden)
                continue

            # Output table header with column labels (one table per section)
            output.append('\n<h2>{} Options</h2>'.format(groupName.title()))
            output.append('<table class="program-options"><thead><tr>')
            output.append('<th>{}</th><th>{}</th><th>{}</th>'.format('Name', 'Type', 'Description'))
            output.append('</tr></thead><tbody>')

            # Sort options by name and output table rows
            for optionName, option in sorted(groupPeek[1], key=lambda elem: elem[0]):

                # Skip options marked as hidden
                if option["hidden"]:
                    continue

                # Recover JSON syntax, because the Python representation uses [u'this format']
                default = json.dumps(option["default"])

                # Parse and re-format the optional field for possible values
                # (not fully safe, but ', 'is unlikely to occur in strings)
                try:
                    optionList = option["values"].partition('Possible values: ')[2].split(', ')
                    values = formatList(optionList, '<br/>Possible values:\n')
                except KeyError:
                    values = ''

                # Expected data type for argument
                valueType = option["type"]

                # Upper-case first letter, period at the end, HTML entities
                description = option["description"].strip()
                description = description[0].upper() + description[1:]
                if description[-1] != '.':
                    description += '.'
                description = escape(description)

                # Description, default value and possible values separated by line breaks
                descriptionCombined = '\n'.join([description, '<br/>Default: <code>{}</code>'.format(default), values])

                output.append('<tr><td><code>{}</code></td><td>{}</td><td>{}</td></tr>'.format(optionName, valueType, descriptionCombined))

            output.append('</tbody></table>')

        # Join output and register as docublock (like 'program_options_arangosh')
        dokuBlocks[0]['program_options_' + program.lower()] = '\n'.join(output) + '\n\n'

#################################################################################

if __name__ == '__main__':
    sys.exit(main())
