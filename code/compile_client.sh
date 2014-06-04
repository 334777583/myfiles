#!/bin/bash

##########################################################################################
##  C6 魂曲 客户端自动编译脚本
##  Author: 许昭鹏(OdinXu@gmail.com)
##  Last-modified: 2012/09/25
##  需要下载FLEX_SDK4及安装JRE6
##########################################################################################

LIB_COMPILE_BIN=/usr/local/lib/flex_sdk_4/bin/compc
MAIN_COMPILE_BIN=/usr/local/lib/flex_sdk_4/bin/mxmlc

SECURE_SWF_JAR="/usr/local/secureSWF/secureSWF.jar"
JAVA_VM="java"
JAVA_ARG="-Xmx1024m"
SECURE_SWF_CMD="$JAVA_VM $JAVA_ARG -jar $SECURE_SWF_JAR"

TMP_DIR=$1
ENCRYPT_OPTION=$2
ENCRYPT_KEY=$3

if [ ! -d "$TMP_DIR"  -o "$TMP_DIR" = '' ] ; then
    echo "=====无法找到构建的源码目录:$TMP_DIR====="
    exit 1
fi 

if [ "$ENCRYPT_OPTION" = '' -o "$ENCRYPT_KEY" = '' ]; then
    echo "======编译参数错误====="
    exit 1
fi
get_include_classes() {
    DIR=$1
    CLASS_FILES=`ls $DIR`
    CLASSES_LIST_STR=''
    PACKAGE=''
    if [ "$2" != '' ] ; then
        PACKAGE="$2."
    fi
    for CLASS_FILE in $CLASS_FILES
    do
        if [ -d $DIR/$CLASS_FILE ] ; then
             CLASSES_LIST_STR=$CLASSES_LIST_STR`get_include_classes $DIR/$CLASS_FILE $PACKAGE$CLASS_FILE`
        else
             CLASS_FILE_END=`echo ${CLASS_FILE} | cut -d '.' -f2`
             if [ "$CLASS_FILE_END" = 'as' ] ; then
                 CLASS_NAME=`echo ${CLASS_FILE} | cut -d '.' -f1`
                 CLASSES_LIST_STR="${CLASSES_LIST_STR},${PACKAGE}${CLASS_NAME}"
             fi
        fi
    done 
    echo $CLASSES_LIST_STR
}

get_res_encode_opt(){
    if [ "$ENCRYPT_OPTION" = "--encrypt" ] ; then
        echo "-define=CONFIG::encode,true -define=CONFIG::key,${ENCRYPT_KEY}"
    else
        echo "-define=CONFIG::encode,false"
    fi
}

compile_lib(){
    SOURCE_PATH=$1
    OUTPUT=$2
    CLASSES=$3
    LIB=$4
    LIB_PATH_OPT=''
    RES_ENCODE_OPT=$(get_res_encode_opt)
    CUSTOM_FLAG=$5
    if [ "$LIB" != '' ] ; then
        LIB_PATH_OPT="-library-path+=$LIB"
    fi

    echo `$LIB_COMPILE_BIN $LIB_PATH_OPT -source-path+=$SOURCE_PATH -debug=false -optimize=true -include-classes=$CLASSES -output=$OUTPUT $RES_ENCODE_OPT $5` 
}

compile_main(){
    SOURCE_PATH=$1
    SOURCE_MAIN_FILE=$2
    OUTPUT=$3
    LIB=$4
    CUSTOM_FLAG=$5
    RES_ENCODE_OPT=$(get_res_encode_opt)
    echo `$MAIN_COMPILE_BIN -source-path+=$SOURCE_PATH $SOURCE_MAIN_FILE -static-link-runtime-shared-libraries=true -optimize=true -output $OUTPUT -library-path+=$LIB -debug=false $5 $RES_ENCODE_OPT`
}


echo '========= 清除之前编译生成的swf ========='
mkdir -p ${TMP_DIR}/bin
rm -f $TMP_DIR/bin/GameComponent.swc
rm -f $TMP_DIR/bin/GameCore.swc
rm -f $TMP_DIR/bin/GameWorld.swf
rm -f $TMP_DIR/bin/CreateRole.swf
rm -f $TMP_DIR/bin/GameLoader.swf


echo '=========开始编译 GameComponent 库========='
COMPONENT_SRC_ROOT=$TMP_DIR/GameComponent/src
COMPONENT_INCLUDE_CLASSES=`get_include_classes $COMPONENT_SRC_ROOT/ ''`
COMPONENT_INCLUDE_CLASSES=${COMPONENT_INCLUDE_CLASSES:1}

COMPONENT_SWC_PATH=$TMP_DIR/bin/GameComponent.swc
compile_lib $COMPONENT_SRC_ROOT/ $COMPONENT_SWC_PATH $COMPONENT_INCLUDE_CLASSES



echo '=========开始编译 GameCore 库========='
GAMECORE_LIB_DIR=$TMP_DIR/GameCore/lib
GAMECORE_SRC_ROOT=$TMP_DIR/GameCore/src
GAMECORE_INCLUDE_CLASSES=`get_include_classes $GAMECORE_SRC_ROOT/ ''`
GAMECORE_INCLUDE_CLASSES=${GAMECORE_INCLUDE_CLASSES:1}

GAMECORE_SWC_PATH=$TMP_DIR/bin/GameCore.swc

cp -f $COMPONENT_SWC_PATH  $GAMECORE_LIB_DIR/

compile_lib $GAMECORE_SRC_ROOT/ $GAMECORE_SWC_PATH $GAMECORE_INCLUDE_CLASSES $GAMECORE_LIB_DIR  



echo '=========开始编译创角页 NewCreateRole ========='
compile_main $TMP_DIR/NewCreateRole/src $TMP_DIR/NewCreateRole/src/CreateRole.as $TMP_DIR/bin/CreateRole.swf $TMP_DIR/bin 

echo '=========开始编译Loading页 GameLoader ========='
compile_main $TMP_DIR/GameLoader/src $TMP_DIR/GameLoader/src/GameLoader.as $TMP_DIR/bin/GameLoader.swf $TMP_DIR/bin 

echo '=========开始编译主程序 GameWorld ========='
compile_main $TMP_DIR/GameWorld/src $TMP_DIR/GameWorld/src/game/client/GameWorld.as $TMP_DIR/bin/GameWorld.swf $TMP_DIR/bin/

if [ "$ENCRYPT_OPTION" = "--encrypt" ] ; then
    echo '========= 开始加密客户端 ========='
    cp $TMP_DIR/GameWorld/bin/GameWorld.ssp4 $TMP_DIR/bin/GameWorld.ssp4
    $SECURE_SWF_CMD run $TMP_DIR/bin/ $TMP_DIR/bin/GameWorld.ssp4
    mv $TMP_DIR/bin/secure_GameWorld.swf $TMP_DIR/bin/GameWorld.swf
    rm $TMP_DIR/bin/GameWorld.ssp4
fi


echo '=========编译 客户端程序 全部完成========='

