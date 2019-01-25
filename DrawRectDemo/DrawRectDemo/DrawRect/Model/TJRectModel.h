//
//  TJRectModel.h
//  OpenCVFaceDetectDemo
//
//  Created by WZT on 2018/11/14.
//  Copyright © 2018年 WZT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TJLineModel.h"
#import <UIKit/UIKit.h>

@protocol TJRectModelDelegate <NSObject>

-(void)redrawRect;

@end

@interface TJRectModel : NSObject

@property (nonatomic, weak) id<TJRectModelDelegate> delegate;

@property (nonatomic, assign) CGFloat max_width;
@property (nonatomic, assign) CGFloat max_height;

//顶点坐标数组ABCD+线段中位点EFGH
@property (nonatomic, strong) NSMutableArray *pointsArray;
//顶点坐标ABCD
@property (nonatomic, readonly) NSMutableArray *cornerPoints;
@property (nonatomic, assign) BOOL isInQuadrilateral;     //是否是内四边形

//限制只进行矩形位移
@property (nonatomic, assign) BOOL isOnlyRectMoving;


#pragma mark 四边形判断准则1 - 根据x/y轴坐标
//检测是否为内四边形
-(BOOL)justifyIsInQuadrilateralWithIndex:(NSInteger)index;
-(void)justfyFourCornerPointsAndToDoSomething:(NSMutableArray*)cornerPoints;

#pragma mark public methods

//重绘
-(void)redraw;
//NSArray <-->CGPoint 转换
-(CGPoint)getCGPointWithNumbersArray:(NSArray*)numberArr;
-(NSArray*)getNumbersArrayWithCGPoint:(CGPoint)point;
//检测触摸点是否在交点范围内
-(NSInteger)searchPointContainedTouch:(CGPoint)touch;
//手势拖动边的中点时，根据中间点的位移，确定两端点的位移
-(void)resetTwoPointsByCenterPointWithTouch:(CGPoint)touchPoint;
//根据四个顶点坐标，初始化四边形四条边的中间点
-(void)initCenterPointBetweenTwo;
-(BOOL)isTouchRectWithPoint:(CGPoint)point;

//将数组按照y轴坐标升序排列
-(NSArray*)resetOrderOfCornerPointsByABCD:(NSArray*)points;

#pragma mark 手势触摸事件
-(void)touchBeginWithPoint:(CGPoint)point;
-(void)touchMovingWithPoint:(CGPoint)point;
-(void)touchEndWithPoint:(CGPoint)point;
-(void)touchCancelWithPoint:(CGPoint)point;

@end

