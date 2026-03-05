//
//  MIKMediaInfo.m
//  MediaInfoKit
//
//  This software is released subject to licensing conditions as detailed in
//  LICENCE.md
//
// References :
// https://mediaarea.net/fr/MediaInfo/Support/SDK/Quick_Start#Quick_Start

#import "MIKMediaInfo.h"
#import "NSString+MIK.h"

#import "MediaInfoDLL_Static.h"

static const NSInteger paddingLenth = 30;

#define FONT_ATTR_DICT(fn, fs)                                                 \
  @{NSFontAttributeName : [NSFont fontWithName:fn size:fs]}

#pragma mark - MIKMediaInfo private

@interface MIKMediaInfo ()

@property(readwrite, strong) NSMutableArray *streamNames;
@property(readwrite, strong) NSMutableDictionary *streamsOrder;
@property(readwrite, strong) NSMutableDictionary *streamsInfo;
@property(readwrite, strong) NSURL *fileURL;
@property(readwrite, assign) void *mediaInfoHandle; // MediaInfoDLL::MediaInfo*

@end

#pragma mark - MIKMediaInfo implementation

@implementation MIKMediaInfo

/// C++ MediaInfoDLL 的 setlocale 调用非线程安全，
/// 必须在任何实例创建之前全局调用一次。
/// +initialize 由 ObjC 运行时保证线程安全且只调用一次。
+ (void)initialize {
  setenv("LC_CTYPE", "UTF-8", 0);
  // 全局设置 locale，对所有后续 MediaInfo 实例生效
  // 移至此处后, initWithFileURL: 无需再 per-instance 调用，也无需加锁
  MediaInfoDLL::MediaInfo::Option_Static(
      [@"setlocale_LC_CTYPE" mik_WCHARString], [@"UTF-8" mik_WCHARString]);
}

- (nullable instancetype)initWithFileURL:(NSURL *)fileURL {
  self = [super init];
  if (self) {
    self.fileURL = fileURL;

    // 无需加锁：setlocale 已在 +initialize 中全局设置一次
    // 不同 MediaInfo 实例的构造和 Open() 可完全并发执行
    MediaInfoDLL::MediaInfo *mi = new MediaInfoDLL::MediaInfo();

    // 使用 getBytes 拷贝到自有缓冲区，避免 cStringUsingEncoding
    // 临时指针偶发脏数据
    NSString *pathStr = [fileURL path];
    NSUInteger len = [pathStr length];
    size_t bufSize = (len + 1) * sizeof(wchar_t);
    wchar_t *filename = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
    if (!filename) {
      NSLog(@"MediaInfo cannot allocate buffer for path: %@", pathStr);
      delete mi;
      self = nil;
      return self;
    }
    NSUInteger usedLength = 0;
    [pathStr getBytes:filename
             maxLength:bufSize - sizeof(wchar_t)
            usedLength:&usedLength
              encoding:NSUTF32LittleEndianStringEncoding
               options:0
                 range:NSMakeRange(0, len)
        remainingRange:NULL];

    size_t res = mi->Open(filename);
    free(filename);

    if (!res) {
      NSLog(@"MediaInfo cannot open file: %@", fileURL.path);
      delete mi;
      self = nil;
    } else {
      // Store the MediaInfo handle for raw value queries
      self.mediaInfoHandle = mi;

      // Build stream info using pure API (no text parsing)
      [self buildStreamInfoFromAPI:mi];

      // Note: We keep the file open and mi object alive for raw value queries
      // It will be closed and deleted in dealloc
    }
  }
  return self;
}

- (void)dealloc {
  if (self.mediaInfoHandle) {
    MediaInfoDLL::MediaInfo *mi =
        (MediaInfoDLL::MediaInfo *)self.mediaInfoHandle;
    mi->Close();
    delete mi;
    self.mediaInfoHandle = nullptr;
  }
}

/// 使用纯 API 构建流信息（不解析任何文本）
- (void)buildStreamInfoFromAPI:(void *)handle {
  MediaInfoDLL::MediaInfo *mi = (MediaInfoDLL::MediaInfo *)handle;

  self.streamNames = [NSMutableArray array];
  self.streamsOrder = [NSMutableDictionary dictionary];
  self.streamsInfo = [NSMutableDictionary dictionary];

  // 统计每种流类型的数量
  NSMutableDictionary *streamTypeCounts = [NSMutableDictionary dictionary];
  for (int kind = 0; kind < MediaInfoDLL::Stream_Max; kind++) {
    size_t count = mi->Count_Get((MediaInfoDLL::stream_t)kind);
    if (count > 0) {
      // 获取流类型名称（永远是英文）
      std::basic_string<MediaInfoDLL::Char> typeStr = mi->Get(
          (MediaInfoDLL::stream_t)kind, 0, [@"StreamKind" mik_WCHARString]);
      NSString *typeName = [[NSString alloc] mik_initWithWCHAR:typeStr.c_str()];
      streamTypeCounts[typeName] = @(count);
    }
  }

  // 遍历所有流
  for (int kind = 0; kind < MediaInfoDLL::Stream_Max; kind++) {
    MediaInfoDLL::stream_t streamKind = (MediaInfoDLL::stream_t)kind;
    size_t streamCount = mi->Count_Get(streamKind);

    for (size_t streamPos = 0; streamPos < streamCount; streamPos++) {
      // 获取流名称（英文）
      std::basic_string<MediaInfoDLL::Char> typeStr =
          mi->Get(streamKind, streamPos, [@"StreamKind" mik_WCHARString]);
      NSString *typeName = [[NSString alloc] mik_initWithWCHAR:typeStr.c_str()];

      // 构建流名称
      NSString *streamName;
      if ([streamTypeCounts[typeName] integerValue] == 1) {
        streamName = typeName;
      } else {
        streamName =
            [NSString stringWithFormat:@"%@ #%zu", typeName, streamPos + 1];
      }

      // 获取参数
      NSMutableArray *paramOrder = [NSMutableArray array];
      NSMutableDictionary *paramInfo = [NSMutableDictionary dictionary];

      size_t paramCount = mi->Count_Get(streamKind, streamPos);
      for (size_t paramIdx = 0; paramIdx < paramCount; paramIdx++) {
        // 检查是否显示在 Inform() 中
        std::basic_string<MediaInfoDLL::Char> options = mi->Get(
            streamKind, streamPos, paramIdx, MediaInfoDLL::Info_Options);
        if (options.empty() || options[0] != 'Y') {
          continue; // 跳过不显示的参数
        }

        // 获取翻译后的参数名
        std::basic_string<MediaInfoDLL::Char> nameStr = mi->Get(
            streamKind, streamPos, paramIdx, MediaInfoDLL::Info_Name_Text);
        // 获取翻译后的参数值
        std::basic_string<MediaInfoDLL::Char> valueStr =
            mi->Get(streamKind, streamPos, paramIdx, MediaInfoDLL::Info_Text);

        if (!nameStr.empty() && !valueStr.empty()) {
          NSString *name = [[NSString alloc] mik_initWithWCHAR:nameStr.c_str()];
          NSString *value =
              [[NSString alloc] mik_initWithWCHAR:valueStr.c_str()];
          [paramOrder addObject:name];
          [paramInfo setObject:value forKey:name];
        }
      }

      [self.streamNames addObject:streamName];
      [self.streamsOrder setObject:paramOrder forKey:streamName];
      [self.streamsInfo setObject:paramInfo forKey:streamName];
    }
  }
}

#pragma mark Informations

- (NSArray<NSString *> *)streamKeys {
  return (_streamNames != nil) ? _streamNames : @[];
}

- (NSDictionary<NSString *, NSString *> *)valuesForStreamKey:
    (NSString *)streamKey {
  return (self.streamsInfo[streamKey]) ?: @{};
}

- (NSDictionary *)streams {
  NSMutableDictionary *streams = [NSMutableDictionary dictionary];
  for (NSString *streamKey in self.streamKeys) {
    NSDictionary *streamInfo = [self valuesForStreamKey:streamKey];
    [streams setObject:streamInfo forKey:streamKey];
  }
  return streams;
}

- (NSInteger)countOfValuesForStreamKey:(NSString *)streamKey {
  return [self valuesForStreamKey:streamKey].count;
}

- (nullable NSString *)keyAtIndex:(NSInteger)index
                     forStreamKey:(NSString *)streamKey {
  return [self.streamsOrder objectForKey:streamKey][index];
}

- (nullable NSString *)valueAtIndex:(NSInteger)index
                       forStreamKey:(NSString *)streamKey {
  NSString *key = [self keyAtIndex:index forStreamKey:streamKey];
  return [self valueForKey:key streamKey:streamKey];
}

- (nullable NSString *)valueForKey:(NSString *)infoKey
                         streamKey:(NSString *)streamKey {
  return [self valuesForStreamKey:streamKey][infoKey];
}

#pragma mark Text representation

- (NSString *)text {
  __block NSMutableString *text = [NSMutableString string];

  for (NSString *streamKey in self.streamKeys) {
    [text appendFormat:@"%@ :\n", streamKey];
    [self enumerateValuesForStreamKey:streamKey
                              inOrder:YES
                                block:^(NSString *key, NSString *val) {
                                  key =
                                      [key stringByPaddingToLength:paddingLenth
                                                        withString:@" "
                                                   startingAtIndex:0];
                                  [text appendFormat:@"%@ : %@\n", key, val];
                                }];
    [text appendString:@"\n"];
  }

  if (text.length > 0) {
    [text deleteCharactersInRange:NSMakeRange(text.length - 1, 1)];
  }

  return text;
}

- (NSAttributedString *)attributedText {
  __block NSMutableAttributedString *text =
      [[NSMutableAttributedString alloc] init];
  __block NSDictionary *titleAttr = FONT_ATTR_DICT(@"Courier-Bold", 13.0);
  __block NSDictionary *valueAttr = FONT_ATTR_DICT(@"Courier", 11.0);

  for (NSString *streamKey in self.streamKeys) {
    [text mik_appendAtrributes:titleAttr string:streamKey];
    [text mik_appendAtrributes:titleAttr string:@"\n"];
    [self enumerateValuesForStreamKey:streamKey
                              inOrder:YES
                                block:^(NSString *key, NSString *val) {
                                  key =
                                      [key stringByPaddingToLength:paddingLenth
                                                        withString:@" "
                                                   startingAtIndex:0];
                                  NSString *line = [NSString
                                      stringWithFormat:@"%@ : %@\n", key, val];
                                  [text mik_appendAtrributes:valueAttr
                                                      string:line];
                                }];
    [text mik_appendAtrributes:titleAttr string:@"\n"];
  }

  if (text.length > 0) {
    [text deleteCharactersInRange:NSMakeRange(text.length - 1, 1)];
  }

  return text;
}

- (NSString *)xmlText {
  NSMutableString *xmlString = [[NSMutableString alloc] init];

  for (NSString *streamKey in self.streamKeys) {
    NSDictionary *streamInfo = [self valuesForStreamKey:streamKey];
    [xmlString appendFormat:@"<%@>\n", streamKey];
    for (NSString *key in [streamInfo allKeys]) {
      NSString *value = streamInfo[key];
      [xmlString appendFormat:@"    <%@>%@</%@>\n", key, value, key];
    }
    [xmlString appendFormat:@"</%@>\n", streamKey];
  }
  return [NSString stringWithString:xmlString];
}

- (NSString *)jsonText {
  NSError *jsonError = nil;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:[self streams]
                                      options:NSJSONWritingPrettyPrinted
                                        error:&jsonError];
  if (jsonError) {
    NSLog(@"%@ %s jsonError: error: %@", self, __PRETTY_FUNCTION__,
          jsonError.localizedDescription);
  }
  if (!jsonData) {
    return nil;
  }

  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)plistText {
  NSError *plistError = nil;
  NSData *plistData = [NSPropertyListSerialization
      dataWithPropertyList:[self streams]
                    format:NSPropertyListXMLFormat_v1_0
                   options:0
                     error:&plistError];

  if (plistError) {
    NSLog(@"%@ %s plistError: error: %@", self, __PRETTY_FUNCTION__,
          plistError.localizedDescription);
  }
  if (!plistData) {
    return nil;
  }
  return [[NSString alloc] initWithData:plistData
                               encoding:NSUTF8StringEncoding];
}

- (NSAttributedString *)attributedTextForFormat:(MIKFormat)format {
  NSString *text = nil;
  switch (format) {
  case MIKFormatRTF:
    return [self attributedText];
  case MIKFormatTXT:
    text = [self text];
    break;
  case MIKFormatXML:
    text = [self xmlText];
    break;
  case MIKFormatJSON:
    text = [self jsonText];
    break;
  case MIKFormatPLIST:
    text = [self plistText];
    break;
  default:
    NSLog(@"%@ %s format argument is invalid", self, __PRETTY_FUNCTION__);
    break;
  }
  return (text) ? [[NSAttributedString alloc] initWithString:text] : nil;
}

#pragma mark Enumeration

- (void)enumerateValuesForStreamKey:(NSString *)streamKey
                              block:(MIKStreamEnumerationBlock)block {
  [self enumerateValuesForStreamKey:streamKey inOrder:NO block:block];
}

- (void)enumerateOrderedValuesForStreamKey:(NSString *)streamKey
                                     block:(MIKStreamEnumerationBlock)block {
  [self enumerateValuesForStreamKey:streamKey inOrder:YES block:block];
}

- (void)enumerateOrderedValues:(MIKStreamEnumerationBlock)block
                  forStreamKey:(NSString *)streamKey {
  [self enumerateValuesForStreamKey:streamKey inOrder:YES block:block];
}

- (void)enumerateValuesForStreamKey:(NSString *)streamKey
                            inOrder:(BOOL)ordered
                              block:(MIKStreamEnumerationBlock)block {
  NSDictionary *info = self.streamsInfo[streamKey];
  NSArray *keys = (ordered) ? self.streamsOrder[streamKey] : info.allKeys;
  for (NSString *key in keys) {
    NSString *value = info[key];
    if (value) {
      block(key, value);
    }
  }
}

#pragma mark Exportation

- (BOOL)writeAsTXTToURL:(NSURL *)fileURL atomically:(BOOL)useAuxiliaryFile {
  NSString *infoString = [self text];
  NSError *txtError = nil;
  BOOL success = [infoString writeToURL:fileURL
                             atomically:useAuxiliaryFile
                               encoding:NSUTF8StringEncoding
                                  error:&txtError];
  if (txtError) {
    NSLog(@"%@", [txtError localizedDescription]);
  }
  return success;
}

- (BOOL)writeAsRTFToURL:(NSURL *)fileURL atomically:(BOOL)useAuxiliaryFile {
  NSAttributedString *infoString = [self attributedText];

  NSError *rtfError;
  NSDictionary *docAttr =
      @{NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType};
  NSData *rtfData =
      [infoString dataFromRange:NSMakeRange(0, [infoString length])
             documentAttributes:docAttr
                          error:&rtfError];
  if (rtfError) {
    NSLog(@"%@", [rtfError localizedDescription]);
  }

  return [rtfData writeToURL:fileURL atomically:useAuxiliaryFile];
}

- (BOOL)writeAsXMLToURL:(NSURL *)fileURL atomically:(BOOL)useAuxiliaryFile {

  NSString *xmlString = [self xmlText];
  NSError *xmlError = nil;
  BOOL success = [xmlString writeToURL:fileURL
                            atomically:useAuxiliaryFile
                              encoding:NSUTF8StringEncoding
                                 error:&xmlError];
  if (xmlError) {
    NSLog(@"%@", [xmlError localizedDescription]);
  }
  return success;
}

- (BOOL)writeAsJSONToURL:(NSURL *)fileURL atomically:(BOOL)useAuxiliaryFile {
  NSError *jsonError = nil;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:[self streams]
                                      options:NSJSONWritingPrettyPrinted
                                        error:&jsonError];
  if (jsonError) {
    NSLog(@"%@", [jsonError localizedDescription]);
  }
  return [jsonData writeToURL:fileURL atomically:useAuxiliaryFile];
}

- (BOOL)writeAsPLISTToURL:(NSURL *)fileURL atomically:(BOOL)useAuxiliaryFile {
  return [[self streams] writeToURL:fileURL atomically:useAuxiliaryFile];
}

+ (NSString *)extensionForFormat:(MIKFormat)format {
  NSString *extension = nil;
  switch (format) {
  case MIKFormatTXT:
    extension = @"txt";
    break;
  case MIKFormatRTF:
    extension = @"rtf";
    break;
  case MIKFormatXML:
    extension = @"xml";
    break;
  case MIKFormatJSON:
    extension = @"json";
    break;
  case MIKFormatPLIST:
    extension = @"plist";
    break;
  default:
    break;
  }
  return extension;
}

- (BOOL)writeAsFormat:(MIKFormat)format toURL:(NSURL *)fileURL {
  return [self writeAsFormat:format toURL:fileURL atomically:YES];
}

- (BOOL)writeAsFormat:(MIKFormat)format
                toURL:(NSURL *)fileURL
           atomically:(BOOL)flag {
  BOOL success = NO;
  switch (format) {
  case MIKFormatTXT:
    success = [self writeAsTXTToURL:fileURL atomically:flag];
    break;
  case MIKFormatRTF:
    success = [self writeAsRTFToURL:fileURL atomically:flag];
    break;
  case MIKFormatXML:
    success = [self writeAsXMLToURL:fileURL atomically:flag];
    break;
  case MIKFormatJSON:
    success = [self writeAsJSONToURL:fileURL atomically:flag];
    break;
  case MIKFormatPLIST:
    success = [self writeAsPLISTToURL:fileURL atomically:flag];
    break;
  default:
    NSLog(@"%@ %s format argument is invalid", self, __PRETTY_FUNCTION__);
    break;
  }
  return success;
}

#pragma mark Options

+ (void)setUseInternetConnection:(BOOL)use {
  const wchar_t *value =
      use ? [@"No" mik_WCHARString] : [@"Yes" mik_WCHARString];
  MediaInfoDLL::MediaInfo::Option_Static([@"Internet" mik_WCHARString], value);
}

+ (void)setLanguageWithContents:(NSString *)langContents {
  MediaInfoDLL::MediaInfo::Option_Static([@"Language" mik_WCHARString],
                                         [langContents mik_WCHARString]);
}

#pragma mark Raw Values

- (nullable NSString *)getRawValue:(NSString *)valueKey
                      forStreamKey:(NSString *)streamKey {
  if (!self.mediaInfoHandle) {
    NSLog(@"MediaInfo handle is not available");
    return nil;
  }

  MediaInfoDLL::MediaInfo *mi = (MediaInfoDLL::MediaInfo *)self.mediaInfoHandle;

  // Map stream key to MediaInfo stream kind
  MediaInfoDLL::stream_t streamKind = MediaInfoDLL::Stream_Max;
  if ([streamKey isEqualToString:@"General"]) {
    streamKind = MediaInfoDLL::Stream_General;
  } else if ([streamKey isEqualToString:@"Video"] ||
             [streamKey hasPrefix:@"Video"]) {
    streamKind = MediaInfoDLL::Stream_Video;
  } else if ([streamKey isEqualToString:@"Audio"] ||
             [streamKey hasPrefix:@"Audio"]) {
    streamKind = MediaInfoDLL::Stream_Audio;
  } else if ([streamKey isEqualToString:@"Text"] ||
             [streamKey hasPrefix:@"Text"]) {
    streamKind = MediaInfoDLL::Stream_Text;
  } else if ([streamKey isEqualToString:@"Other"]) {
    streamKind = MediaInfoDLL::Stream_Other;
  } else if ([streamKey isEqualToString:@"Image"]) {
    streamKind = MediaInfoDLL::Stream_Image;
  } else if ([streamKey isEqualToString:@"Menu"]) {
    streamKind = MediaInfoDLL::Stream_Menu;
  }

  if (streamKind == MediaInfoDLL::Stream_Max) {
    NSLog(@"Unknown stream key: %@", streamKey);
    return nil;
  }

  // Get raw value (Info_Text returns the raw value, not formatted)
  std::basic_string<MediaInfoDLL::Char> rawValue = mi->Get(
      streamKind, 0, [valueKey mik_WCHARString], MediaInfoDLL::Info_Text);

  if (rawValue.empty()) {
    return nil;
  }

  return [[NSString alloc] mik_initWithWCHAR:rawValue.c_str()];
}

- (nullable NSString *)getFormattedValue:(NSString *)valueKey
                            forStreamKey:(NSString *)streamKey {
  if (!self.mediaInfoHandle) {
    NSLog(@"MediaInfo handle is not available");
    return nil;
  }

  MediaInfoDLL::MediaInfo *mi = (MediaInfoDLL::MediaInfo *)self.mediaInfoHandle;

  // Map stream key to MediaInfo stream kind
  MediaInfoDLL::stream_t streamKind = MediaInfoDLL::Stream_Max;
  if ([streamKey isEqualToString:@"General"]) {
    streamKind = MediaInfoDLL::Stream_General;
  } else if ([streamKey isEqualToString:@"Video"] ||
             [streamKey hasPrefix:@"Video"]) {
    streamKind = MediaInfoDLL::Stream_Video;
  } else if ([streamKey isEqualToString:@"Audio"] ||
             [streamKey hasPrefix:@"Audio"]) {
    streamKind = MediaInfoDLL::Stream_Audio;
  } else if ([streamKey isEqualToString:@"Text"] ||
             [streamKey hasPrefix:@"Text"]) {
    streamKind = MediaInfoDLL::Stream_Text;
  } else if ([streamKey isEqualToString:@"Other"]) {
    streamKind = MediaInfoDLL::Stream_Other;
  } else if ([streamKey isEqualToString:@"Image"]) {
    streamKind = MediaInfoDLL::Stream_Image;
  } else if ([streamKey isEqualToString:@"Menu"]) {
    streamKind = MediaInfoDLL::Stream_Menu;
  }

  if (streamKind == MediaInfoDLL::Stream_Max) {
    NSLog(@"Unknown stream key: %@", streamKey);
    return nil;
  }

  // Append "/String" to get formatted value
  NSString *formattedKey = [valueKey stringByAppendingString:@"/String"];

  // Get formatted value
  std::basic_string<MediaInfoDLL::Char> formattedValue = mi->Get(
      streamKind, 0, [formattedKey mik_WCHARString], MediaInfoDLL::Info_Text);

  if (formattedValue.empty()) {
    return nil;
  }

  return [[NSString alloc] mik_initWithWCHAR:formattedValue.c_str()];
}

- (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)
       getValues:(NSArray<NSString *> *)keys
    forStreamKey:(NSString *)streamKey {
  if (!self.mediaInfoHandle) {
    NSLog(@"MediaInfo handle is not available");
    return @{};
  }

  if (keys.count == 0) {
    return @{};
  }

  MediaInfoDLL::MediaInfo *mi = (MediaInfoDLL::MediaInfo *)self.mediaInfoHandle;

  // Map stream key to MediaInfo stream kind
  MediaInfoDLL::stream_t streamKind = MediaInfoDLL::Stream_Max;
  if ([streamKey isEqualToString:@"General"]) {
    streamKind = MediaInfoDLL::Stream_General;
  } else if ([streamKey isEqualToString:@"Video"] ||
             [streamKey hasPrefix:@"Video"]) {
    streamKind = MediaInfoDLL::Stream_Video;
  } else if ([streamKey isEqualToString:@"Audio"] ||
             [streamKey hasPrefix:@"Audio"]) {
    streamKind = MediaInfoDLL::Stream_Audio;
  } else if ([streamKey isEqualToString:@"Text"] ||
             [streamKey hasPrefix:@"Text"]) {
    streamKind = MediaInfoDLL::Stream_Text;
  } else if ([streamKey isEqualToString:@"Other"]) {
    streamKind = MediaInfoDLL::Stream_Other;
  } else if ([streamKey isEqualToString:@"Image"]) {
    streamKind = MediaInfoDLL::Stream_Image;
  } else if ([streamKey isEqualToString:@"Menu"]) {
    streamKind = MediaInfoDLL::Stream_Menu;
  }

  if (streamKind == MediaInfoDLL::Stream_Max) {
    NSLog(@"Unknown stream key: %@", streamKey);
    return @{};
  }

  NSMutableDictionary *result =
      [NSMutableDictionary dictionaryWithCapacity:keys.count];

  for (NSString *key in keys) {
    NSMutableDictionary *valuePair =
        [NSMutableDictionary dictionaryWithCapacity:2];

    // Get raw value
    std::basic_string<MediaInfoDLL::Char> rawValue =
        mi->Get(streamKind, 0, [key mik_WCHARString], MediaInfoDLL::Info_Text);

    if (!rawValue.empty()) {
      valuePair[@"raw"] = [[NSString alloc] mik_initWithWCHAR:rawValue.c_str()];
    }

    // Get formatted value
    NSString *formattedKey = [key stringByAppendingString:@"/String"];
    std::basic_string<MediaInfoDLL::Char> formattedValue = mi->Get(
        streamKind, 0, [formattedKey mik_WCHARString], MediaInfoDLL::Info_Text);

    if (!formattedValue.empty()) {
      valuePair[@"formatted"] =
          [[NSString alloc] mik_initWithWCHAR:formattedValue.c_str()];
    }

    // Only add to result if we got at least one value
    if (valuePair.count > 0) {
      result[key] = valuePair;
    }
  }

  return result;
}

- (NSDictionary<
    NSString *,
    NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *> *)
    getAllValues:(NSDictionary<NSString *, NSArray<NSString *> *> *)keysDict {

  if (keysDict.count == 0) {
    return @{};
  }

  NSMutableDictionary *result =
      [NSMutableDictionary dictionaryWithCapacity:keysDict.count];

  // Iterate through each stream and get its values
  for (NSString *streamKey in keysDict) {
    NSArray<NSString *> *keys = keysDict[streamKey];
    if (keys.count > 0) {
      NSDictionary *streamValues = [self getValues:keys forStreamKey:streamKey];
      if (streamValues.count > 0) {
        result[streamKey] = streamValues;
      }
    }
  }

  return result;
}

- (nullable NSNumber *)getDurationInMilliseconds:(NSString *)streamKey {
  NSString *durationString = [self getRawValue:@"Duration"
                                  forStreamKey:streamKey];

  if (!durationString) {
    return nil;
  }

  // Duration is returned in milliseconds as a string
  long long durationMs = [durationString longLongValue];
  return @(durationMs);
}

@end
