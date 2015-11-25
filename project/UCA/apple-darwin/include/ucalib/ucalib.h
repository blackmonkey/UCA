/*
 * Copyright (c) 2012, MAIPU Technologies, Inc.
 * All rights reserved.
 *
 * This program is UCA project Code.
 *
 * Authors: wangzhijun, quanjh
 * Revision History:  Date: July 05, 2012
 */

#ifndef UCALIB_H_
#define UCALIB_H_

#define IN
#define OUT

#if !defined(FALSE)
#define FALSE 0
#endif
#if !defined(TRUE)
#define TRUE 1
#endif

#define FRONTCAM  1
#define BACKCAM 2

#define AUDIO_MODE  0
#define VIDEO_MODE  1

#define UCALIBSDK_VERSION  "Ver 0.8.12"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/**
 * @addtogroup 错误码
 * @{
 **/

/**
 * 系统错误码
 * @version UcaLibSDK 0.1
 **/
typedef enum
{
    /// 正确
    UCALIB_ERR_OK,
    /// 未知错误
    UCALIB_ERR_UNKNOWN,
    /// 参数错误
    UCALIB_ERR_BADPARAM,
    /// 同时只允许登录一个帐号，请退出之前登录的帐号
    UCALIB_ERR_MULTILOGIN,
    /// Soap访问错误
    UCALIB_ERR_SOAPERROR,
    /// 用户名或密码错误
    UCALIB_ERR_BADAUTH,
    /// 修改密码时，老密码错误
    UCALIB_ERR_BADOLDPASSWD,
    ///新密码为空错误
    UCALIB_ERR_NEWPASSWD,
    ///有一个电话正在运行
    UCALIB_ERR_CALL_WORKED,
    /// 未实现
    UCALIB_ERR_NOTIMP,
    /// 无效的句柄
    UCALIB_ERR_INVALIDHANDLE,
    /// 网络不可达
    UCALIB_ERR_NETWORKUNREACHABLE,
    ///传输文件过大
    UCALIB_SFP_SEND_FILE_TOOLARGE
} UCALIB_ERRCODE;

/**
 * @}
 **/

/**
 * @addtogroup 登录与注销
 * @{
 **/

/**
 * 登录句柄
 * @version UcaLibSDK 0.1
 **/
typedef unsigned int UCALIB_LOGIN_HANDLE, *UCALIB_PLOGIN_HANDLE;

/**
 * 登录参数结构
 * @version UcaLibSDK 0.1
 **/
typedef struct
{
    /// UCA服务器地址.
    char *serverIP;
    /// UCA服务器端口，为0表示取默认值.
    unsigned short serverPort;
    /// 源地址,应用层忽略.
    char *srcAddr;
    /// 源端口,应用层忽略.
    unsigned short srcPort;
    /// 登录用户名.
    char *username;
    /// 登录密码.
    char *password;
} UCALIB_LOGIN_PARAM, *UCALIB_PLOGIN_PARAM;

typedef struct UCALIB_SFP_PARAM{
    char *filePathName;
    char *shortFileName;
    char *fileType;
    char *fileSize;
}UCALIB_SFP_PARAM, *UCALIB_PSFP_PARAM;
/**
 * 登录状态
 * @version UcaLibSDK 0.1
 **/
typedef enum
{
    /// 无
    UCALIB_LOGIN_STATE_NONE,
    /// 正在登录中
    UCALIB_LOGIN_STATE_PROGRESS,
    /// 登录成功
    UCALIB_LOGIN_STATE_OK,
    /// 退出成功
    UCALIB_LOGIN_STATE_EXIT,
    /// 登录失败
    UCALIB_LOGIN_STATE_FAIL
} UCALIB_LOGIN_STATE;

/**
 * @brief ucaLib_Login函数向UCA服务器发起用户登录流程，用户信息由参数param提供。
 * @param [in] param : 设置登录信息，比如服务器地址，用户名，密码等。
 * @param [out] handle : 如果成功，则返回登录句柄。该句柄会用于后继相关函数调用。
 * @retval UCALIB_ERR_OK 调用成功。后继通过回调函数CBK_LoginState获取登录成功与失败状态。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述。可能的错误码有：UCALIB_ERR_MULTILOGIN,UCALIB_ERR_SOAPERROR,UCALIB_ERR_BADAUTH等。
 * @version UcaLibSDK 0.1
 **/
UCALIB_ERRCODE ucaLib_Login(IN UCALIB_PLOGIN_PARAM param, OUT UCALIB_PLOGIN_HANDLE handle);

/**
 * @brief ucaLib_Logout函数向UCA服务器发起退出流程。
 * @param [in] handle : ucaLib_Login返回的句柄
 * @retval UCALIB_ERR_OK 调用成功。后继通过回调函数CBK_LoginState获取退出成功与失败状态。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.1
 **/
UCALIB_ERRCODE ucaLib_Logout(IN UCALIB_LOGIN_HANDLE handle);

/**
 * @brief ucaLib_ChangePasswd函数修改用户登录密码。
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] oldPasswd : 之前的密码
 * @param [in] newPasswd : 新的密码
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述。可能的错误码有：UCALIB_ERR_BADOLDPASSWD等。
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_ChangePasswd(IN UCALIB_LOGIN_HANDLE handle, IN const char *oldPasswd, IN const char *newPasswd);

/**
 * @}
 **/


/**
 * @addtogroup 呈现状态
 * @{
 **/

/**
 * 用户的呈现状态
 * @version UcaLibSDK 0.1
 **/
typedef enum
{
    /// 在线
    UCALIB_PRESENTATIONSTATE_ONLINE,
    /// 离开，当界面一段时间内无任何操作时
    UCALIB_PRESENTATIONSTATE_AWAY,
    /// 忙碌
    UCALIB_PRESENTATIONSTATE_BUSY,
    /// 会议中
    UCALIB_PRESENTATIONSTATE_MEETING,
    /// 免扰
    UCALIB_PRESENTATIONSTATE_DONTBREAK,
    /// 离线
    UCALIB_PRESENTATIONSTATE_OFFLINE
} UCALIB_PRESENTATIONSTATE;

/**
 * 更改呈现状态的结果
 * @version UcaLibSDK 0.1
 **/
typedef enum
{
    /// 呈现状态改变成功
    UCALIB_PRESENTATIONRESULT_CODE_OK,
    /// 呈现状态改变失败，上层UI应该将此失败信息告知用户
    UCALIB_PRESENTATIONRESULT_CODE_ERROR
} UCALIB_PRESENTATIONRESULT_CODE;

/**
 * @brief ucaLib_ChangePresentation 函数改变用户自己的呈现状态
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] state : 需要设置的呈现状态
 * @retval UCALIB_ERR_OK 调用成功。后继通过回调函数CBK_PresentationState获取呈现状态改变成功与失败信息。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.1
 **/
UCALIB_ERRCODE ucaLib_ChangePresentation(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_PRESENTATIONSTATE state);

/**
 * @brief ucaLib_Subscribe 函数订阅好友或群组的呈现状态。订阅成功后，通过CBK_PresentationNotifyList获取好友或群组状态改变通知。
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uri : 订阅的uri，若为NULL，则表示订阅所有好友的呈现状态。若为"sip:img-1096@sipserver.test.com",则表示为群组订阅呈现,1096为获取用户群组列表中的群组ID号。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.5
 **/
UCALIB_ERRCODE ucaLib_Subscribe(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri);

/**
 * @brief ucaLib_UnSubscribe 函数取消订阅好友或群组的呈现状态。
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uri : 取消订阅的uri，若为NULL，则表示取消订阅所有好友的呈现状态。若为"sip:img-1096@sipserver.test.com",则表示取消订阅群组的呈现状态,1096为获取用户群组列表中的群组ID号。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.5
 **/
UCALIB_ERRCODE ucaLib_UnSubscribe(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri);

/**
 * @}
 **/


/**
 * @addtogroup 用户联系人管理
 * @{
 **/

/**
 * @brief ucaLib_GetFriends 函数获取登录用户的所有好友和所有私有联系人
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [out] friendsXml : 用户的好友信息, 必须ucaLib_Free释放此分配内存。格式参见“获取用户好友和私有联系人的编码格式”
 * @param [out] privatesXml : 用户的私有联系人信息, 必须ucaLib_Free释放此分配内存。格式参见“获取用户好友和私有联系人的编码格式”
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_GetFriends(IN UCALIB_LOGIN_HANDLE handle, OUT char **friendsXml, OUT char **privatesXml);

/**
 * @brief ucaLib_ManageFriends 函数为添加删除好友
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 管理好友输入的信息, 格式参见“管理好友添加删除的编码格式”
 * @param [in] outXml : 管理好友输出的信息, 必须ucaLib_Free释放此分配内存。格式参见“管理好友添加删除的编码格式”
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_ManageFriends(IN UCALIB_LOGIN_HANDLE handle, IN const char *inXml,OUT char **outXml);

/**
 * @brief ucaLib_ManagePrivate 函数为管理私有联系人增加删除修改功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 管理私有联系人输入的信息, 格式参见“管理私有联系人添加删除修改的编码格式”
 * @param [in] outXml : 管理私有联系人输出的信息, 必须ucaLib_Free释放此分配内存。格式参见“管理私有联系人添加删除修改的编码格式”
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_ManagePrivate(IN UCALIB_LOGIN_HANDLE handle,IN const char *inXml, OUT char **outXml);

/**
 * @brief ucaLib_GetPersonInfo 函数为获取特定用户的信息功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 输入的信息, 格式参见“获取特定用户的信息编码格式”
 * @param [in] outXml : 输出的信息, 必须ucaLib_Free释放此分配内存。格式参见“获取特定用户的信息编码格式”
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_GetPersonInfo(IN UCALIB_LOGIN_HANDLE handle,IN const char *inXml, OUT char **outXml);

/**
 * @}
 **/


/**
 * @addtogroup 搜索联系人和组织架构信息
 * @{
 **/

/**
 * @brief ucaLib_SearchInfo 函数搜索联系人和组织架构信息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 搜索输入的信息, 格式参见“搜索联系人和组织架构的编码格式”
 * @param [out] outXml : 搜索输出的信息, 必须调用ucaLib_Free释放此分配内存。格式参见“搜索联系人和组织架构的编码格式”
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_SearchInfo(IN UCALIB_LOGIN_HANDLE handle, IN const char* inXml, OUT char **outXml);

/**
 * @brief ucaLib_SearchInfoById 函数通过部门ID搜索部门信息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 搜索输入的信息。格式参见“通过部门ID搜索信息的编码格式”
 * @param [out] outXml : 搜索输出的信息, 必须调用ucaLib_Free释放此分配内存。格式参见“通过部门ID搜索信息的编码格式”
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_SearchInfoById(IN UCALIB_LOGIN_HANDLE handle, IN const char* inXml, OUT char **outXml);

/**
 * @}
 **/

/**
 * @addtogroup 固定群组
 * @{
 **/

/**
 * @brief ucaLib_GetGroupList 函数为获取用户固定群组列表
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [out] outXml : 固定群组列表信息, 必须用ucaLib_Free释放此分配内存, 格式参见“固定群组组列表的编码格式”。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_GetGroupList(IN UCALIB_LOGIN_HANDLE handle, OUT char **outXml);

/**
 * @brief ucaLib_ManageGroup 函数为管理固定群组,仅群组管理员可操作.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 输入的信息, 格式参见 "管理固定群组成员的编码格式"。
 * @param [in] outXml : 输出参数保留,暂时未使用。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_ManageGroup(IN UCALIB_LOGIN_HANDLE handle, IN const char *inXml, OUT char **outXml);


/**
 * @brief ucaLib_ManageGroupMember 函数为管理固定群组的成员,仅群组管理员可操作.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 输入的信息, 格式参见 "管理固定群组成员的编码格式"。
 * @param [out] outXml : 输出的信息, 必须调用ucaLib_Free释放此分配内存,格式参见 "管理固定群组成员的编码格式"。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_ManageGroupMember(IN UCALIB_LOGIN_HANDLE handle, IN const char *inXml, OUT char **outXml);

/**
 * @brief ucaLib_GetGroupMemberInfo 函数为根据固定群组的ID获取群组成员信息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] inXml : 输入的信息, 格式参见 "根据固定群组的ID获取群组成员的编码格式"。
 * @param [out] outXml : 输出的信息, 必须调用ucaLib_Free释放此分配内存,格式参见 "根据固定群组的ID获取群组成员的编码格式"。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_GetGroupMemberInfo(IN UCALIB_LOGIN_HANDLE handle, IN const char *inXml,OUT char **outXml);

/**
 * @}
 **/

/**
 * @brief ucaLib_MsgConfCreate 函数为多人会话创建接口
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [out] confid : 发起多人会话的ID.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.3
 **/
UCALIB_ERRCODE ucaLib_MsgConfCreate(IN UCALIB_LOGIN_HANDLE handle,OUT int *confid);

/**
 * @brief ucaLib_MsgConfJoinOther 函数为邀请某人加入会话的接口
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] confid : 邀请人加入的回话ID.
 * @param [in] uri: 邀请人的uri. 例如邀请张三,张三的uri"zhangsan@218.255.24.151"
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.3
 **/
UCALIB_ERRCODE ucaLib_MsgConfJoinOther(IN UCALIB_LOGIN_HANDLE handle,IN int confid,IN const char *uri);

/**
 * @brief ucaLib_MsgConfClose 函数为关闭多人会话接口
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] confid : 多人会话的ID.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.3
 **/
UCALIB_ERRCODE ucaLib_MsgConfClose(IN UCALIB_LOGIN_HANDLE handle, IN int confid);

/**
 * @}
 **/

/**
 * @addtogroup 服务器与本地配置
 * @{
 **/

/**
 * 选择服务端配置方式
 * @version UcaLibSDK 0.4
 **/
typedef enum
{
    /// 服务器域名[只读]            格式为 "字符串"
    UCALIB_CONFIGKEY_SERVERDOMAINNAME,
    /// 组织架构公司名称[只读]      格式为 "字符串"
    UCALIB_CONFIGKEY_CUSTOMHISOTLOGYNAME,
    /// 服务器更新服务配置[只读]    格式参见 "获取服务器更新服务信息的编码格式"
    UCALIB_SERVER_UPDATESERVICE,
    /// 服务器权限配置[只读]        格式参见 "获取服务器权限信息的编码格式"
    UCALIB_SERVER_PERMISSION,
    /// 服务器系统用户的信息[读写]  格式参见 "获取服务器系统用户信息的编码格式"
    UCALIB_SERVER_USERINFO,
} UCALIB_SERVER_CONFIG;

/**
 * @brief ucaLib_GetServerConfig 函数获取服务器端配置信息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] key : 对应配置项键值
 * @param [out] value  : 对应配置项的输出信息,必须调用ucaLib_Free释放此分配内存, 格式参见“获取服务器配置信息的编码格式”。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_GetServerConfig(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_SERVER_CONFIG key, OUT char **value );

/**
 * @brief ucaLib_SetServerConfig 函数设置服务器端配置信息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] key : 对应配置项键值
 * @param [in] value : 对应配置项的输入信息，格式参见“修改服务器用户自己的信息编码格式”。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.4
 **/
UCALIB_ERRCODE ucaLib_SetServerConfig(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_SERVER_CONFIG key, IN const char *value);

/**
 * 本地配置项
 * @version UcaLibSDK 0.7
 **/
typedef enum
{
    /// 音频编解码，支持SPEEX/PCMU/PCMA/G729[读写]
    UCALIB_AUDIO_CODEC,
    /// 视频编解码，支持H263/H264[读写]
    UCALIB_VIDEO_CODEC,
    /// 音频输入设备信息 [只读]
    UCALIB_AUDIO_INPUT,
    /// 音频输出设备信息 [只读]
    UCALIB_AUDIO_OUTPUT,
    /// 音频响铃设备信息 [只读]
    UCALIB_AUDIO_RING,
    /// 视频显示设备信息 [只读]
    UCALIB_VIDEO_DEVICE,
} UCALIB_LOCAL_CONFIG;

/**
 * @brief ucaLib_LocalConfig 函数为本地信息配置
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] key : 对应配置项键值
 * @param [in] inValue : 输入的信息,格式参见 "本地配置信息的编码格式"
 * @param [out] outValue : 输出的信息,必须调用ucaLib_Free释放此分配内存。格式参见 "本地配置信息的编码格式"
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_LocalConfig(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_LOCAL_CONFIG key, IN const char *inValue, OUT char **outValue);

/**
 * @brief ucaLib_GetSipTransport 函数为获取会话传输端口
 * @param [in] retValue : 对应端口字符串 "例: "TCP", "UDP", "TLS""
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.9
 **/
UCALIB_ERRCODE ucaLib_GetSipTransport (OUT char **retValue);

/**
 * @brief ucaLib_SetSipTransports 函数为设置会话传输端口
 * @param [in] portValue : 对应端口字符串 "例: "TCP", "UDP", "TLS""
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.9
 **/
UCALIB_ERRCODE ucaLib_SetSipTransports (IN const char *portValue);

/**
 * @brief ucalib_core_set_network_reachable 函数为根据网络是否可达, 进行自动注册.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] value : 对应值为TRUE或FALSE, 注意只有切换网络时调用此接口,否则绝不用.严格参考"linphone接口linphone_core_set_network_reachable的实现机制".
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucalib_set_network_reachable(IN UCALIB_LOGIN_HANDLE handle,IN const int value);

/**
 * @brief ucalib_is_network_reachabled 函数为根据网络是否可达, 进行自动注册.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [out] status : 对应值为TRUE或FALSE "TRUE表示为网络可达状态; FALSE表示网络不可达"
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucalib_is_network_reachabled(IN UCALIB_LOGIN_HANDLE handle,OUT int *status);

/**
 * @brief ucalib_enable_log_infos 函数为日志显示控制.
 * @param [in] flag : 对应值为TRUE或FALSE "TRUE表示为开启日志信息; FALSE表示关闭日志信息"
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.6
 **/
UCALIB_ERRCODE ucalib_enable_log_infos(IN int flag);

/**
 * @}
 **/

/**
 * @addtogroup 即时消息
 * @{
 **/

/**
 * @brief ucaLib_SendMsg 函数向对方发送一条即时消息
 * @brief 即时消息格式为html格式
 * @brief 表情编码格式为： /[xxx] 其中xxx为表情名称，例如/[微笑]表示发送一个微笑的表情
 * @brief IM中带图片格式为：<img jt="true" src="Sunset.jpg"/> ，Sunset.jpg为图片的文件名
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uri : 对方的uri
 * @param [in] htmlMsg : 消息内容。
 * @param [in] toWhoUri : 保留
 * @retval UCALIB_ERR_OK 调用成功。若此消息发送失败，会在CBK_SystemMessage回调函数中收到UCALIB_SYSTEM_MESSAGE_MSG_CANTREACH的系统消息
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_SendMsg(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri, IN const char *htmlMsg, IN const char *toWhoUri);

/**
 * @}
 **/

/**
 * @addtogroup 语音通话
 * @{
 **/

/**
 * @brief ucaLib_CallInvite 函数为发起通话功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] peerUri : 被叫方的Uri
 * @param [in] mode : 参考宏定义为AUDIO_MODE和VIDEO_MODE两种模式
 * @param [out] callId : 返回的通话callId
 * @retval UCALIB_ERR_OK 调用成功
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_CallInvite(IN UCALIB_LOGIN_HANDLE handle, IN const char *peerUri, IN const int mode, OUT int *callId);

/**
 * @brief ucaLib_CallHangUp 函数为挂断通话功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 通话中的callId
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_CallHangUp(IN UCALIB_LOGIN_HANDLE handle, IN const int callId);

/**
 * @brief ucaLib_CallAccept 函数为接收通话功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 接收通话的callId, 在call回调函数中取得
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_CallAccept(IN UCALIB_LOGIN_HANDLE handle, IN const int callId);

/**
 * @brief ucaLib_CallCancel 函数为取消通话功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 通话中的callId
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_CallCancel(IN UCALIB_LOGIN_HANDLE handle, IN const int callId);

/**
 * @brief ucaLib_CallPause 函数为暂停通话功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 通话中的callId
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_CallPause(IN UCALIB_LOGIN_HANDLE handle, IN const int callId);

/**
 * @brief ucaLib_CallResume 函数为恢复通话功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 通话中的callId
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.3
 **/
UCALIB_ERRCODE ucaLib_CallResume(IN UCALIB_LOGIN_HANDLE handle, IN const int callId);

/**
 * 键码值枚举
 * @version UcaLibSDK 0.3
 **/
typedef enum
{
 /// 拨号键码值 1
 UCALIB_DIAL_KEY1='1',
 /// 拨号键码值 2
 UCALIB_DIAL_KEY2='2',
 /// 拨号键码值 3
 UCALIB_DIAL_KEY3='3',
 /// 拨号键码值 4
 UCALIB_DIAL_KEY4='4',
 /// 拨号键码值 5
 UCALIB_DIAL_KEY5='5',
 /// 拨号键码值 6
 UCALIB_DIAL_KEY6='6',
 /// 拨号键码值 7
 UCALIB_DIAL_KEY7='7',
 /// 拨号键码值 8
 UCALIB_DIAL_KEY8='8',
 /// 拨号键码值 9
 UCALIB_DIAL_KEY9='9',
 /// 拨号键码值 0
 UCALIB_DIAL_KEY0='0',
 /// 拨号键码值 *
 UCALIB_DIAL_KEYASTERISK='*',
 /// 拨号键码值 #
 UCALIB_DIAL_KEYWELL='#',
}UCALIB_DIAL_KEYCODE;
/**
 * @brief ucaLib_DtmfKeyDown 函数为模拟按键压下
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] key : 按键码索引值, 参见UCALIB_DIAL_KEYCODE枚举
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_DtmfKeyDown(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_DIAL_KEYCODE key);

/**
 * @brief ucaLib_CallKeyUp 函数为模拟按键弹起
 * @param [in] handle : ucaLib_Login返回的句柄
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_DtmfKeyUp(IN UCALIB_LOGIN_HANDLE handle);

/**
 * @brief ucaLib_MuteMic 函数为通话是否静音操作
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] active : TRUE 设置为静音, FALSE 设置为非静音
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_MuteMic(IN UCALIB_LOGIN_HANDLE handle, IN const int active);

/**
 * @brief ucaLib_MicMuted 函数为通话静音状态确认
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [OUT] active : TRUE 目前为静音状态, FALSE 目前为非静音状态
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_MicMuted(IN UCALIB_LOGIN_HANDLE handle, OUT  int *active);

/**
 * @brief ucaLib_SetRing 函数为设置铃声
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] path : 铃声路径,格式仅支持wav "例如: /rings/world.wav"
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.7
 **/
UCALIB_ERRCODE ucaLib_SetRing(IN UCALIB_LOGIN_HANDLE handle, IN const char *path);

/**
 * @brief ucaLib_BlindTransferCall 函数为呼叫转移功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 呼叫操作中的callId
 * @param [in] uri : 需要转移到对端的uri
 * @retval UCALIB_ERR_OK 调用成功
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.8
 **/
UCALIB_ERRCODE ucaLib_BlindTransferCall(IN UCALIB_LOGIN_HANDLE handle, IN const unsigned long callId, IN const char *uri);

/**
 * @}
 **/

/**
 * @addtogroup 视频通话
 * @{
 **/

/**
 * @brief ucaLib_video_enabled 函数为判断视频是否使能.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [out] active : 返回TRUE表示开启视频, 返回FALSE表示关闭视频.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.5
 **/
UCALIB_ERRCODE ucaLib_video_enabled (IN UCALIB_LOGIN_HANDLE handle, OUT int *active);

/**
 * @brief ucaLib_enable_video 函数为控制视频开关，体现在设置模块中是否开启视频.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] active : TRUE传入表示开启视频, FALSE传入表示关闭视频.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_enable_video(IN UCALIB_LOGIN_HANDLE handle, IN const int active);

/**
 * @brief ucaLib_get_camera_support函数为获取摄像头支持情况
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] cam : IOS平台[FRONTCAM 表示前置摄像头, BACKCAM 表示后置摄像头]
 * @param [out] active : TRUE为支持,FALSE为不支持
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.5
 **/
UCALIB_ERRCODE ucaLib_get_camera_support(IN UCALIB_LOGIN_HANDLE handle, IN const int cam,OUT int *active);

/**
 * @brief ucaLib_get_current_camera 函数为获取当前摄像头状态
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] status : IOS平台[FRONTCAM 表示前置摄像头, BACKCAM 表示后置摄像头]
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8.5
 **/
UCALIB_ERRCODE ucaLib_get_current_camera(IN UCALIB_LOGIN_HANDLE handle, OUT int *status);

/**
 * @brief ucaLib_camera_change 函数为前后摄像头切换功能
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] active : IOS平台[FRONTCAM 表示前置摄像头, BACKCAM 表示后置摄像头],WIN32平台待定
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_camera_change(IN UCALIB_LOGIN_HANDLE handle, IN const int active);

/**
 * @brief ucaLib_enable_video_preview 函数为控制视频预览窗口.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] active : TRUE表示显示预览窗口, FALSE表示关闭预览窗口.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_enable_video_preview (IN UCALIB_LOGIN_HANDLE handle, IN const int active);

/**
 * @brief ucaLib_set_native_video_window_id 函数为远端视频显示控制.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] id : id为视频显示窗口句柄.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_set_native_video_window_id (IN UCALIB_LOGIN_HANDLE handle, IN unsigned long id);

/**
 * @brief ucaLib_set_native_preview_window_id 函数为近端视频预览显示控制.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] id : id为本地视频预览显示窗口句柄.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_set_native_preview_window_id (IN UCALIB_LOGIN_HANDLE handle, IN unsigned long id);

/**
 * @brief ucaLib_get_device_rotation 函数为获取设备旋转状态.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [out] rotation : 为旋转状态值,例如 0,90,270.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_get_device_rotation(IN UCALIB_LOGIN_HANDLE handle, OUT int *rotation);

/**
 * @brief ucaLib_set_device_rotation 函数为设置设备旋转状态.
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] rotation : 设置旋转状态值,例如 0,90,270.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_set_device_rotation(IN UCALIB_LOGIN_HANDLE handle, IN int rotation);


/**
 * @}
 **/


/**
 * @brief ucaLib_SfpSendFile 函数为文件发送接口
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] peerUri : 发送文件对端得uri
 * @param [in] fileName : 发送文件绝对路径 例如：c:/dir/sendfile.txt
 * @param [in] shortName : 发送文件名称
 * @param [in] fileType : 发送文件类型,没有类型用星号代替。例如: txt, doc等，README的文件类型为 *
 * @param [in] fileSize : 发送文件大小
 * @param [in] speed : 发送文件速度要求，目前为保留未使用
 * @param [out] sId : 发送文件返回的ID
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_SfpSendFile(IN UCALIB_LOGIN_HANDLE handle, IN const char *peerUri, IN const char *fileName,
            IN const char *shortName, IN const char *fileType, IN const char *fileSize, IN const float speed, OUT int *sId);

/**
 * @brief ucaLib_SfpRecvFile 函数为接收文件接口
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] fileName : 接收文件的名字,由回调函数sfpStatus来获得,回调中的from来匹配用户.
 * @param [in] fid : 传入接口文件的ID值.
 * @param [in] iscontine : 保留类型，目的是为了断点续传.
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.8
 **/
UCALIB_ERRCODE ucaLib_SfpRecvFile(IN UCALIB_LOGIN_HANDLE handle, IN const char *fileName, IN const int fid, IN const int iscontine);

/**
 * @addtogroup 回调函数
 * @{
 **/

/**
 * 系统消息码。
 * @version UcaLibSDK 0.1
 **/
typedef enum
{
    /// 您的帐号在别处登录
    UCALIB_SYSTEM_MESSAGE_CODE_KICKOFF,
    /// 即时消息发送失败，msg中包含此条消息的内容。
    UCALIB_SYSTEM_MESSAGE_MSG_CANTREACH,
    /// 错误，msg参数中包含错误的信息
    UCALIB_SYSTEM_MESSAGE_ERROR,
}UCALIB_SYSTEM_MESSAGE_CODE;

/**
 * @brief 上层注册该回调函数，获取系统消息。
 * @param [in] msgCode : 消息码id
 * @param [in] msg : 消息内容
 * @retval 无
 * @version UcaLibSDK 0.1
 **/
typedef void (*CBK_SystemMessage)(IN UCALIB_SYSTEM_MESSAGE_CODE msgCode, IN const char *msg);

/**
 * @brief 上层注册该回调函数，获取登录状态信息。
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] state : 当前状态
 * @param [in] result : 当前状态的结果
 * @retval 无
 * @version UcaLibSDK 0.1->0.4
 **/
typedef void (*CBK_LoginState)(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_LOGIN_STATE state, IN UCALIB_ERRCODE result);

/**
 * @brief 上层注册该回调函数，获取改变呈现状态成功或失败信息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] status : 当前的呈现状态
 * @param [in] result : 呈现状态改变结果
 * @retval 无
 * @version UcaLibSDK 0.4
 **/
typedef void (*CBK_PresentationState)(IN UCALIB_LOGIN_HANDLE handle, IN UCALIB_PRESENTATIONSTATE status, IN UCALIB_PRESENTATIONRESULT_CODE result);

/**
 * @brief 上层注册该回调函数，获取接收到的即时消息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uri : 消息发送方的uri
 * @param [in] htmlMsg : 消息内容。
 * @retval 无
 * @version UcaLibSDK 0.1
 **/
typedef void (*CBK_IMMsg)(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri, IN const char *htmlMsg);

/**
 * @brief 上层注册该回调函数，获取接收到多人会话或群组会话的即时消息
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] from : 多人会话或群组会话中消息发送方的uri
 * @param [in] to : 多人会话或群组会话的uri
 * @param [in] towhom :多人会话或群组会话中，特定到某人会话的uri
 * @param [in] htmlMsg : 多人会话或群组会话的消息内容。
 * @retval 无
 * @version UcaLibSDK 0.8.3
 **/
typedef void (*CBK_Chat_IMMsg)(IN UCALIB_LOGIN_HANDLE handle, IN const char *from, IN const char *to, IN const char *towhom, IN const char *htmlMsg);


/**
 * @brief 上层注册该回调函数，获取好友呈现状态变化的通知
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uri : 呈现状态变化方的uri
 * @param [in] state : 呈现状态
 * @retval 无
 * @version UcaLibSDK 0.1
 **/
typedef void (*CBK_PresentationNotify)(IN UCALIB_LOGIN_HANDLE handle, IN const char *uri, IN UCALIB_PRESENTATIONSTATE state);

/**
 * @brief 上层注册该回调函数，批量获取有关联的使用者呈现状态变化通知
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uriFmt : 用户操作获取的uri格式字符串
 * @param [in] xmlMsg : 返回有关联的使用者信息, 格式参见 "关联使用者呈现的XML信息格式"
 * @retval 无
 * @version UcaLibSDK 0.5
 **/
typedef void (*CBK_PresentationNotifyList)(IN UCALIB_LOGIN_HANDLE handle, IN const char *uriFmt, IN const char *xmlMsg);

/**
 * @brief 上层注册该回调函数，批量获取成员变化通知
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] uriFmt : 用户操作获取的uri格式字符串,这里用来区分群组和多人会话
 * @param [in] xmlMsg : 返回有关联的使用者信息, 格式参见 "关联使用者状态变化的XML信息格式"
 * @retval 无
 * @version UcaLibSDK 0.8.4
 **/
typedef void (*CBK_MemberChangeNotifyList)(IN UCALIB_LOGIN_HANDLE handle, IN const char *uriFmt, IN const char *xmlMsg);

/**
 * 通话状态。
 * @version UcaLibSDK 0.3
 **/
typedef enum
{
    /// 空闲
    UCALIB_CALLSTATUS_IDLE,
    /// 收到呼叫, 状态的callid做为接收通话的callid
    UCALIB_CALLSTATUS_INCOMING_RECEIVED,
    /// 开始拨出电话
    UCALIB_CALLSTATUS_OUTGOING_INIT,
    /// 拨出电话在进行连接中
    UCALIB_CALLSTATUS_OUTGOING_PROGRESS,
    /// 拨出电话, 对端处于响铃中
    UCALIB_CALLSTATUS_OUTGOING_RINGING,
    /// 通话建立
    UCALIB_CALLSTATUS_CONNECTED,
    /// 通话建立, 流媒体运行中
    UCALIB_CALLSTATUS_STREAMSRUNNING,
    /// 呼叫暂停中
    UCALIB_CALLSTATUS_PAUSING,
    /// 呼叫暂停
    UCALIB_CALLSTATUS_PAUSED,
    /// 呼叫恢复通话
    UCALIB_CALLSTATUS_RESUMING,
    /// 呼叫结束
    UCALIB_CALLSTATUS_CALLEND,
    /// 呼叫转移中
    UCALIB_CALLSTATUS_REFERED,
   /// 对端呼叫错误,参看param字符串值，为"User is busy",表示对端拒绝来电.在这状态我们可以决定是否重拨.
   UCALIB_CALLSTATUS_CALLERROR
}UCALIB_CALL_STATUS;


/**
 * 文件传输状态类型枚举
 * @version UcaLibSDK 0.8
 **/
typedef enum{
   /// 文件传输空闲状态
   UCALIB_SFP_STATUS_IDLE,
   /// 收到远端文件传输状态
   UCALIB_SFP_STATUS_INCOMING_RECEIVED,
   /// 近端发出文件的初始状态
   UCALIB_SFP_STATUS_OUTGOINGINIT,
   /// 近端文件发送中的状态
   UCBLIB_SFP_STATUS_OUTGOINGPROGRESS,
   /// 传输文件发送成功的状态
   UCALIB_SFP_STATUS_CONNECTED,
   /// 传输文件错误的状态
   UCALIB_SFP_STATUS_ERROR,
   /// 发送文件释放的状态
   UCALIB_SFP_STATUS_RELEASED
}UCALIB_SFP_STATUS;

/**
 * @brief 上层注册该回调函数，获取通话状态变化的通知
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] callId : 邀请和接收通话的callId
 * @param [in] status : 呼叫状态类型
 * @param [in] peerUri : 被叫方的uri
 * @param [in] param :  参数
 * @retval 无
 * @version UcaLibSDK 0.3
 **/
typedef void (*CBK_CallStatus)(IN UCALIB_LOGIN_HANDLE handle, IN const int callId, IN UCALIB_CALL_STATUS status, IN const char *peerUri, IN const void *param);

/**
 * @brief 上层注册该回调函数，获取文件爱你传输状态变化的通知
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] sfpId : 接收文件ID
 * @param [in] status : 文件传输状态信息
 * @param [in] peerUri : 文件传输者的uri
 * @param [in] filename :  文件传输者传输的文件名字
 * @param [in] filesize :  文件传输者传输文件的大小
 * @param [in] param :  参数
 * @retval 无
 * @version UcaLibSDK 0.8
 **/

typedef void (*CBK_SfpStatus)(IN UCALIB_LOGIN_HANDLE handle, IN const int sfpId, IN UCALIB_SFP_STATUS status, IN const char *peerUri, IN const char *filename, IN const char *filesize, IN const char *filetype, IN const void *param);

/**
 * 多人会话状态类型枚举
 * @version UcaLibSDK 0.8.3
 **/
typedef enum{
   /// 多人会话创建成功
   UCALIB_CHAT_CREAT_SUCCEED,
   /// 多人会话创建失败
   UCALIB_CHAT_CREAT_FAILED,
   /// 收到邀请加入多人会话的请求
   UCALIB_CHAT_INVITE_INCOMING,
   /// 邀请其它人加入多人会话成功
   UCALIB_CHAT_REFER_SUCCEED,
   /// 邀请其它人加入多人会话失败
   UCALIB_CHAT_REFER_FAILED,
   /// 收到多人会话的状态通知
   UCALIB_CHAT_NOTIFICATION,
   /// 收到多人会话的成员变化状态通知
   UCALIB_CHAT_IMGROUP_NOTIFICATION
 }UCALIB_CHAT_STATUS;

/**
 * 多人会话错误类型枚举
 * @version UcaLibSDK 0.8.3
 **/
typedef enum{
   /// 无错误
   UCALIB_CHAT_OK,
   /// 内部错误
   UCALIB_CHAT_INTERNAL_ERROR,
   /// 服务器忙
   UCALIB_CHAT_BUSY,
   /// 服务器无应答
   UCALIB_CHAT_NOANSWER,
   /// 请求超时
   UCALIB_CHAT_TIMEOUT,
   /// 服务器错误
   UCALIB_CHAT_SERVER_ERROR,
   /// 网络错误
   UCALIB_CHAT_NETWORK_ERROR,
   /// 未知的错误
   UCALIB_CHAT_UNKNOWN_ERROR
 }UCALIB_CHAT_ERRCODE;
/**
 * @brief 上层注册该回调函数，获取多人会话状态变化的通知
 * @param [in] handle : ucaLib_Login返回的句柄
 * @param [in] chatid : 目前多人会话的ID
 * @param [in] uri : 多人会话时需要的uri.
 * @param [in] status : 多人会话态信息
 * @param [in] param :  参数根据不同状态返回不同的字符串
 * @retval 无
 * @version UcaLibSDK 0.8.3
 **/
typedef void (*CBK_ChatStatus)(IN UCALIB_LOGIN_HANDLE handle,IN const int chatid,IN const char *uri,IN UCALIB_CHAT_STATUS status,IN UCALIB_CHAT_ERRCODE errcode, IN const void *param);


/**
 * 回调函数集，业务层通过回调函数将消息发送到上层。
 * @version UcaLibSDK 0.8.3
 **/
typedef struct
{
    /// 获取系统消息
    CBK_SystemMessage       systemMessage;
    /// 获取登录状态
    CBK_LoginState          loginState;
    /// 获取呈现状态改变结果
    CBK_PresentationState   presentationState;
    /// 获取收到的即时消息
    CBK_IMMsg               imMsg;
    /// 获取收到固定群组或多人会话的即时消息
    CBK_Chat_IMMsg          chatimMsg;
    /// 获取好友的呈现状态变化
    CBK_PresentationNotify    presentationNotify;
    /// 批量获取使用者的呈现状态变化
    CBK_PresentationNotifyList   presentationNotifyList;
    /// 批量获取使用者的成员变化
    CBK_MemberChangeNotifyList   memberChangeNotifyList;
    /// 通话回调状态接口
    CBK_CallStatus          callStatus;
    /// 文件传输回调状态接口
    CBK_SfpStatus           sfpStatus;
    /// 多人会话回调状态接口
    CBK_ChatStatus          chatStatus;
} UCALIB_CBKS;

/**
 * @}
 **/


/**
 * @addtogroup  UCA LIB 的初始化和释放
 * @{
 **/
/**
 * @brief ucaLib_Init函数初始化ucaLib库，uca在启动时需要调用此函数。
 * @param [in] cbks : 回调函数
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.1
 **/
UCALIB_ERRCODE ucaLib_Init(UCALIB_CBKS *cbks);

/**
 * @brief ucaLib_Terminate函数清理ucaLib库，uca在退出时需要调用此函数。
 * @retval UCALIB_ERR_OK 调用成功。
 * @retval 其它 参见错误码UCALIB_ERRCODE描述
 * @version UcaLibSDK 0.1
 **/
UCALIB_ERRCODE ucaLib_Terminate(void);
/**
 * @}
 **/

/**
 * @addtogroup 公共库
 * @{
 **/
/**
 * @brief ucaLib_Sleep函数进入睡眠状态，并持续指定时间。
 * @param [in] usec : 睡眠持续的时间（毫秒）
 * @retval 无
 * @version UcaLibSDK 0.1
 **/
void ucaLib_Sleep(unsigned long long usec);

/**
 * @brief ucaLib_Free释放由ucaLib分配的部分内容。例如：ucaLib_GetFriends函数返回的friendsXml和privatesXml参数，在实用完成后需要调用此接口释放内存。
 * @param [in] p : 需要释放的内存指针
 * @retval 无
 * @version UcaLibSDK 0.1
 **/
void ucaLib_Free(void *p);

#ifdef __cplusplus
} /* extern "C" */
#endif /* __cplusplus */

#endif /* UCALIB_H_ */

/**
 * @}
 **/

