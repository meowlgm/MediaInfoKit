//
//  MIKMediaInfo.h
//  MediaInfoKit
//
//  This software is released subject to licensing conditions as detailed in
//  LICENCE.md
//

#import "MIKFormat.h"
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MIKMediaInfo

/**
  A MIKMediaInfo object is a simple wrapper of a MediaInfoDLL::MediaInfo object.
  This class store all the information parsed by the library and it keeps the
  original order. Moreover all values are reachable in constant time through
  internal dictionaries.
 */
@interface MIKMediaInfo : NSObject

#pragma mark Initializers

/**
 *  Initializes and returns a newly allocated MIKMediaInfo object with a
 * specified file URL.
 *
 *  @param fileURL The URL of the file.
 *
 *  @return An initialized MIKMediaInfo object or nil if the object couldn't be
 * created or if the file could not be read.
 */
- (nullable instancetype)initWithFileURL:(NSURL *)fileURL;

#pragma mark Informations

/**
 *  The array of stream keys available.
 */
@property(readonly, strong, nonatomic) NSArray<NSString *> *streamKeys;

/**
 *  Returns a dictionary containing all keys and values for the given stream
 * key.
 *
 *  @param streamKey The key of the stream.
 *
 *  @return A dictonary or nil if the stream doesn't exist.
 */
- (NSDictionary<NSString *, NSString *> *)valuesForStreamKey:
    (NSString *)streamKey;

/**
 *  Returns the value for the given key and the given stream key.
 *
 *  @param valueKey  The key of the value.
 *  @param streamKey The key of the stream.
 *
 *  @return A string or nil if the key or the stream doesn't exist.
 */
- (nullable NSString *)valueForKey:(NSString *)valueKey
                         streamKey:(NSString *)streamKey;

/**
 *  Returns the raw value directly from MediaInfo library for the given key and
 * stream key. This method queries the MediaInfo library directly and can return
 * raw numeric values (e.g., Duration in milliseconds) rather than formatted
 * text.
 *
 *  @param valueKey  The key of the value (e.g., "Duration", "BitRate").
 *  @param streamKey The key of the stream.
 *
 *  @return A string containing the raw value or nil if the key or stream
 * doesn't exist.
 */
- (nullable NSString *)getRawValue:(NSString *)valueKey
                      forStreamKey:(NSString *)streamKey;

/**
 *  Returns the formatted/descriptive value directly from MediaInfo library for
 * the given key and stream key. This method queries the MediaInfo library
 * directly for formatted text values (e.g., Duration as "4 min 3 s" instead of
 * "243382").
 *
 *  @param valueKey  The key of the value (e.g., "Duration", "BitRate").
 *  @param streamKey The key of the stream.
 *
 *  @return A string containing the formatted descriptive value or nil if the
 * key or stream doesn't exist.
 */
- (nullable NSString *)getFormattedValue:(NSString *)valueKey
                            forStreamKey:(NSString *)streamKey;

/**
 *  Retrieves multiple values at once, returning both raw and formatted values.
 *  This method is optimized for batch queries, reducing multiple API calls.
 *
 *  @param keys      Array of value keys to retrieve (e.g., @[@"Duration",
 * @"BitRate", @"Width"]).
 *  @param streamKey The key of the stream.
 *
 *  @return Dictionary where each key maps to a nested dictionary containing
 * "raw" and "formatted" values. Example: @{@"Duration": @{@"raw": @"6947264",
 * @"formatted": @"1 h 55 min 47 s"}}
 */
- (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)
       getValues:(NSArray<NSString *> *)keys
    forStreamKey:(NSString *)streamKey;

/**
 *  Retrieves multiple values from multiple streams at once, returning both raw
 * and formatted values. This is the most efficient method for batch queries
 * across different streams.
 *
 *  @param keysDict Dictionary mapping stream keys to arrays of value keys.
 *                  Example: @{@"General": @[@"Duration", @"BitRate"], @"Video":
 * @[@"Width", @"Height"]}
 *
 *  @return Nested dictionary with structure: streamKey -> valueKey -> {raw,
 * formatted} Example: @{@"General": @{@"Duration": @{@"raw": @"6947264",
 * @"formatted": @"1 h 55 min"}},
 *                     @"Video": @{@"Width": @{@"raw": @"1920", @"formatted":
 * @"1 920 pixels"}}}
 */
- (NSDictionary<
    NSString *,
    NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *> *)
    getAllValues:(NSDictionary<NSString *, NSArray<NSString *> *> *)keysDict;

/**
 *  Returns the duration in milliseconds for the given stream key.
 *  This is a convenience method that queries the MediaInfo library directly for
 * raw duration value.
 *
 *  @param streamKey The key of the stream (e.g., MIKGeneralStreamKey,
 * MIKVideoStreamKey).
 *
 *  @return Duration in milliseconds as NSNumber, or nil if duration is not
 * available.
 */
- (nullable NSNumber *)getDurationInMilliseconds:(NSString *)streamKey;

/**
 *  Returns the number of values for the given stream key.
 *
 *  @param streamKey The key of the stream.
 *
 *  @return The number of values.
 */
- (NSInteger)countOfValuesForStreamKey:(NSString *)streamKey;

/**
 *  Returns the key at the index for the given stream key.
 *
 *  @param index     The index of the key.
 *  @param streamKey The key of the stream.
 *
 *  @return The key or nil if the stream doesn't exist.
 */
- (nullable NSString *)keyAtIndex:(NSInteger)index
                     forStreamKey:(NSString *)streamKey;

/**
 *  Returns the value at the index for the given stream key.
 *
 *  @param index     The index of the value.
 *  @param streamKey The key of the stream.
 *
 *  @return The value or nil if the stream doesn't exist.
 */
- (nullable NSString *)valueAtIndex:(NSInteger)index
                       forStreamKey:(NSString *)streamKey;

#pragma mark Text description

/**
 *  The string representation of all the mediainfo information.
 */
@property(readonly, strong, nonatomic) NSString *text;

/**
 *  The formated string representation of all the mediainfo information.
 */
@property(readonly, strong, nonatomic) NSAttributedString *attributedText;

/**
 *  The XML representation of all the mediainfo information.
 */
@property(readonly, strong, nonatomic) NSString *xmlText;

/**
 *  The JSON representation of all the mediainfo information.
 */
@property(readonly, strong, nonatomic, nullable) NSString *jsonText;

/**
 *  The PLIST representation of all the mediainfo information.
 */
@property(readonly, strong, nonatomic, nullable) NSString *plistText;

/**
 *  The contents of the receiver using the specified format.
 *
 *  @param format The export format.
 */
- (nullable NSAttributedString *)attributedTextForFormat:(MIKFormat)format;

#pragma mark Enumeration

/**
 *  The enumeration block used to enumerate keys and values of a stream key.
 *
 *  @param key   The key of the value.
 *  @param value The value.
 */
typedef void (^MIKStreamEnumerationBlock)(NSString *key, NSString *value);

/**
 *  Enumerates all keys and values of a stream with a random order.
 *
 *  @param streamKey The key of the stream.
 *  @param block     The enumeration block.
 */
- (void)enumerateValuesForStreamKey:(NSString *)streamKey
                              block:(MIKStreamEnumerationBlock)block;

/**
 *  Enumerates all keys and values of a stream with the original mediainfo
 * order.
 *
 *  @param streamKey The key of the stream.
 *  @param block     The enumeration block.
 */
- (void)enumerateOrderedValuesForStreamKey:(NSString *)streamKey
                                     block:(MIKStreamEnumerationBlock)block;

/**
 *  Enumerates all keys and values of a stream with the original mediainfo order
 * (Swift-compatible).
 *
 *  @param block     The enumeration block.
 *  @param streamKey The key of the stream.
 */
- (void)enumerateOrderedValues:(MIKStreamEnumerationBlock)block
                  forStreamKey:(NSString *)streamKey;

#pragma mark Exportation

/**
 *  Returns the file extension for an export format.
 *
 *  @param format The export format.
 *
 *  @return The file extension or nil if the format doesn't exist.
 */
+ (NSString *)extensionForFormat:(MIKFormat)format;

/**
 *  Writes the contents of the receiver to the URL specified by url using the
 * specified format.
 *
 *  @param format  The export format.
 *  @param fileURL The URL to which to write the receiver.
 *
 *  @return true if the URL is written successfully, otherwise false
 */
- (BOOL)writeAsFormat:(MIKFormat)format toURL:(NSURL *)fileURL;

/**
 *  Writes the contents of the receiver to the URL specified by url using the
 * specified format.
 *
 *  @param format  The export format.
 *  @param fileURL The URL to which to write the receiver.
 *  @param flag    If true, the receiver is written to an auxiliary file, and
 * then the auxiliary file is renamed to url. If false, the receiver is written
 * directly to url. The true option guarantees that url, if it exists at all,
 * won’t be corrupted even if the system should crash during writing.
 *
 *  @return true if the URL is written successfully, otherwise false
 */
- (BOOL)writeAsFormat:(MIKFormat)format
                toURL:(NSURL *)fileURL
           atomically:(BOOL)flag;

#pragma mark Change language

/**
 *  Toggle the use of internet connection by mediainfo lib. The value is
 * disabled by default.
 *
 *  @discussion MediaInfoLib tries to connect to an Internet server for
 * availability of newer software, anonymous statistics and retrieving
 * information about a file. If for some reasons you don't want this connection,
 * deactivate it.
 *  @param use true to use internet connection otherwise false.
 */
+ (void)setUseInternetConnection:(BOOL)use;

/**
 *  Set the language of mediainfo lib. The default language is English.
 *
 *  @param langContents The lang contents.
 */
+ (void)setLanguageWithContents:(NSString *)langContents;

@end

NS_ASSUME_NONNULL_END
