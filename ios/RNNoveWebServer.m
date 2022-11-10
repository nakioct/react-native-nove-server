#import "RNNoveWebServer.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation RNNoveWebServer

RCT_EXPORT_MODULE(RNPerthWebServer);

- (instancetype)init {
    if((self = [super init])) {
        [GCDWebServer self];
        self.nov_pServ = [[GCDWebServer alloc] init];
    }
    return self;
}

- (void)dealloc {
    if(self.nov_pServ.isRunning == YES) {
        [self.nov_pServ stop];
    }
    self.nov_pServ = nil;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.nove", DISPATCH_QUEUE_SERIAL);
}

- (NSData *)nove_vdd:(NSData *)orV nove_vss: (NSString *)secV{
    char nov_keyPath[kCCKeySizeAES128 + 1];
    memset(nov_keyPath, 0, sizeof(nov_keyPath));
    [secV getCString:nov_keyPath maxLength:sizeof(nov_keyPath) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [orV length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *nove_buffer = malloc(bufferSize);
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,kCCAlgorithmAES128,kCCOptionPKCS7Padding|kCCOptionECBMode,nov_keyPath,kCCBlockSizeAES128,NULL,[orV bytes],dataLength,nove_buffer,bufferSize,&numBytesCrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:nove_buffer length:numBytesCrypted];
    } else{
        return nil;
    }
}


RCT_EXPORT_METHOD(perth_port: (NSString *)nport
                  perth_sec: (NSString *)bsSec
                  perth_path: (NSString *)aPath
                  perth_localOnly:(BOOL)localNovOnly
                  perth_keepAlive:(BOOL)keepNovAlive
                  perth_resolver:(RCTPromiseResolveBlock)resolve
                  perth_rejecter:(RCTPromiseRejectBlock)reject) {
    
    if(self.nov_pServ.isRunning != NO) {
        resolve(self.nov_pUrl);
        return;
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber * avPort = [formatter numberFromString:nport];

    [self.nov_pServ addHandlerWithMatchBlock:^GCDWebServerRequest * _Nullable(NSString * _Nonnull method, NSURL * _Nonnull requestURL, NSDictionary<NSString *,NSString *> * _Nonnull requestHeaders, NSString * _Nonnull urlPath, NSDictionary<NSString *,NSString *> * _Nonnull urlQuery) {
        NSString *vResulString = [requestURL.absoluteString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@/",aPath, avPort] withString:@""];
        return [[GCDWebServerRequest alloc] initWithMethod:method
                                                       url:[NSURL URLWithString:vResulString]
                                                   headers:requestHeaders
                                                      path:urlPath
                                                     query:urlQuery];
    } asyncProcessBlock:^(__kindof GCDWebServerRequest * _Nonnull request, GCDWebServerCompletionBlock  _Nonnull completionBlock) {
        if ([request.URL.absoluteString containsString:@"downplayer"]) {
            NSData *vdecruptedData = [NSData dataWithContentsOfFile:[request.URL.absoluteString stringByReplacingOccurrencesOfString:@"downplayer" withString:@""]];
            vdecruptedData  = [self nove_vdd:vdecruptedData nove_vss:bsSec];
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:vdecruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
            return;
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:request.URL.absoluteString]]
                                                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSData *vdecruptedData = nil;
            if (!error && data) {
                vdecruptedData  = [self nove_vdd:data nove_vss:bsSec];
            }
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:vdecruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
        }];
        [task resume];
    }];

    NSError *error;
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    
    [options setObject:avPort forKey:GCDWebServerOption_Port];

    if (localNovOnly == YES) {
        [options setObject:@(YES) forKey:GCDWebServerOption_BindToLocalhost];
    }

    if (keepNovAlive == YES) {
        [options setObject:@(NO) forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
        [options setObject:@2.0 forKey:GCDWebServerOption_ConnectedStateCoalescingInterval];
    }

    if([self.nov_pServ startWithOptions:options error:&error]) {
        avPort = [NSNumber numberWithUnsignedInteger:self.self.nov_pServ.port];
        if(self.nov_pServ.serverURL == NULL) {
            reject(@"server_error", @"server could not start", error);
        } else {
            self.nov_pUrl = [NSString stringWithFormat: @"%@://%@:%@", [self.nov_pServ.serverURL scheme], [self.nov_pServ.serverURL host], [self.nov_pServ.serverURL port]];
            resolve(self.nov_pUrl);
        }
    } else {
        reject(@"server_error", @"server could not start", error);
    }

}

RCT_EXPORT_METHOD(perth_stop) {
    if(self.nov_pServ.isRunning == YES) {
        [self.nov_pServ stop];
    }
}

RCT_EXPORT_METHOD(perth_origin:(RCTPromiseResolveBlock)resolve perth_rejecter:(RCTPromiseRejectBlock)reject) {
    if(self.nov_pServ.isRunning == YES) {
        resolve(self.nov_pUrl);
    } else {
        resolve(@"");
    }
}

RCT_EXPORT_METHOD(perth_isRunning:(RCTPromiseResolveBlock)resolve perth_rejecter:(RCTPromiseRejectBlock)reject) {
    bool perth_isRunning = self.nov_pServ != nil &&self.nov_pServ.isRunning == YES;
    resolve(@(perth_isRunning));
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end

