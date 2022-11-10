#import <React/RCTBridgeModule.h>

#if __has_include("GCDWebServerDataResponse.h")
    #import "GCDWebServer.h"
    #import "GCDWebServerDataResponse.h"
#else
    #import <GCDWebServer/GCDWebServer.h>
    #import <GCDWebServer/GCDWebServerDataResponse.h>
#endif

@interface RNNoveWebServer : NSObject <RCTBridgeModule>

@property(nonatomic, copy) NSString *nov_pUrl;
@property(nonatomic, strong) GCDWebServer *nov_pServ;

@end
  
