//
//  TJPointCircleView.h
//  OpenCVRectDectectDemo
//
//  Created by WZT on 2017/3/20.
//  Copyright © 2017年 WZT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TJRectModel.h"

@protocol TJPointCircleViewDelegate <NSObject>

-(void)changeDetectRect;

@end

@interface TJPointCircleView : UIView

@property (nonatomic, copy, readonly) NSMutableArray <TJRectModel*>*rectsArray;
@property (nonatomic, weak) id<TJPointCircleViewDelegate>delegate;

@property (nonatomic, assign, readonly) BOOL isInQuadrilateral;     //是否是内四边形
//限制只进行矩形位移
@property (nonatomic, assign) BOOL enableOnlyRectMoving;
//是否可编辑
@property (nonatomic, assign) BOOL enableEdite;

#pragma mark public methods
-(void)addARect;
//起点 宽高
-(void)addRectWithOrigin:(CGPoint)origin width:(NSInteger)width height:(NSInteger)height;
//清空之前的绘制
-(void)clearBeforeCircleAndLines;

@end
