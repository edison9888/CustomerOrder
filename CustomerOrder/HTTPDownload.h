//
//  HTTPDownload.h
//  CustomerOrder
//
//  Created by ios on 13-7-11.
//  Copyright (c) 2013年 hxhd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPDownload;
@protocol HTTPDownloadDelegate <NSObject>

@optional
- (void)downloadDidFinishLoading:(HTTPDownload *)hd;
- (void)downloadDidFail:(HTTPDownload *)hd;

@end


@interface HTTPDownload : NSObject<NSURLConnectionDataDelegate,NSURLConnectionDelegate,HTTPDownloadDelegate>
{
    NSMutableData *_mData;
    id <HTTPDownloadDelegate>_delegate;
    NSMutableURLRequest *mRequest;
}

//从指定网址下载数据
- (void)downloadFromURL:(NSString *)url withArgument:(NSString *)argument;

@property (retain,nonatomic)NSMutableData *mData;
@property (assign,nonatomic)id <HTTPDownloadDelegate>delegate;

@end
