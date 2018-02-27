#import "WebkitLocalStorageReader.h"

@implementation WebkitLocalStorageReader

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(get:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

 NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray* libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
  NSString *libraryDir = [libraryPaths objectAtIndex:0];
  NSString *localstoragePath = [libraryDir
                                stringByAppendingPathComponent:@"WebKit/com.timeinc.realsimple.ipad.inapp/WebsiteData/LocalStorage/http_localhost_8080.localstorage"];
  
  // lists all the files in a directory, so you can play around with real device,
  // to find out where the file is saved. This is where I found the localstorage file
  // on a simulator, but I'm not 100% sure this is the same place on a real device.
  // Play around with the path in the line above.
  NSArray* files = [fileManager contentsOfDirectoryAtPath:localstoragePath error:nil];
  
  if ([fileManager fileExistsAtPath:localstoragePath]) {
    
    NSString* fileStuff = [NSString stringWithContentsOfFile:localstoragePath];
    
    sqlite3* db = NULL;
    sqlite3_stmt* stmt =NULL;
    int rc=0;
    NSMutableDictionary *kv = [NSMutableDictionary dictionaryWithDictionary:@{}];
    
    // int len = 0;
    rc = sqlite3_open_v2([localstoragePath UTF8String], &db, SQLITE_OPEN_READONLY , NULL);
    if (SQLITE_OK != rc)
    {
      sqlite3_close(db);
      NSLog(@"Failed to open db connection");
    }
    else
    {
      NSString  * query = @"SELECT key,value FROM ItemTable";
      
      rc =sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, NULL);
      
      
      if (rc == SQLITE_OK)
      {
        while(sqlite3_step(stmt) == SQLITE_ROW )
        {
          // Get key text
          const char *key = (const char *)sqlite3_column_text(stmt, 0);
          NSString *keyString =[[NSString alloc] initWithUTF8String:key];
          
          // Get value as String
          const void *bytes = sqlite3_column_blob(stmt, 1);
          int length = sqlite3_column_bytes(stmt, 1);
          NSData *myData = [[NSData alloc] initWithBytes:bytes length:length];
          NSString *string = [[NSString alloc] initWithData:myData encoding:NSUTF16LittleEndianStringEncoding];
          
          if (string) {
            [kv setObject:string forKey:keyString];
          } else {
            [kv setObject:@"" forKey:keyString];
          }
        }
        sqlite3_finalize(stmt);
      }
      else
      {
        NSLog(@"Failed to prepare statement with rc:%d",rc);
      }
      sqlite3_close(db);
    }
    // THIS IS THE REDUX LOCALSTORAGE!!!!!
    // NSLog(@"REDUX %@", [kv valueForKey:@"redux"]);
    resolve([kv valueForKey:@"redux"]);
  }else{
      resolve(@{});
  }
}

@end
