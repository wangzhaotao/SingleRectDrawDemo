//
//  ViewController.m
//  DrawRectDemo
//
//  Created by ocean on 2019/1/25.
//  Copyright © 2019年 wzt. All rights reserved.
//

#import "ViewController.h"
#import "TJPointCircleView.h"

@interface ViewController ()
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) TJPointCircleView *drawView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //
    [self initUI];
    
    
}

-(void)initUI {
    
    UIView *view = [[UIView alloc]init];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:view];
    _backView = view;
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@(20));
        make.trailing.equalTo(@(-20));
        make.top.equalTo(@(64+20));
        make.bottom.equalTo(@(-60));
    }];
    
    TJPointCircleView *drawView = [[TJPointCircleView alloc]init];
    drawView.isOnlyRectMoving = YES;
    [self.backView addSubview:drawView];
    _drawView = drawView;
    [drawView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.bottom.trailing.equalTo(@0);
    }];
    
    
    UIButton *addBtn = [[UIButton alloc]init];
    [addBtn setTitle:@"添加手势可拖动矩形" forState:UIControlStateNormal];
    [addBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(clickToAddRectAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addBtn];
    [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view.mas_bottom).offset(10);
        make.leading.equalTo(@30);
        make.trailing.equalTo(@(-30));
        make.height.equalTo(@40);
    }];
}

-(void)clickToAddRectAction:(UIButton*)sender {
    
    CGFloat imgW = 200, imgH = 150;
    CGFloat origin_x = (_drawView.bounds.size.width-imgW)/2,
    origin_y = (_drawView.bounds.size.height-imgH)/2;
    [_drawView addRectWithOrigin:CGPointMake(origin_x, origin_y) width:imgW height:imgH];
}


@end
