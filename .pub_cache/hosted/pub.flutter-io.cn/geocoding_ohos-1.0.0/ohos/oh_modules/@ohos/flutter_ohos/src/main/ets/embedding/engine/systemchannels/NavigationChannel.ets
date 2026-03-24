/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd. All rights reserved.
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE_KHZG file.
*
* Based on NavigationChannel.java originally written by
* Copyright (C) 2013 The Flutter Authors.
*
*/

import JSONMethodCodec from '../../../plugin/common/JSONMethodCodec';
import MethodCall from '../../../plugin/common/MethodCall';
import MethodChannel, { MethodCallHandler, MethodResult } from '../../../plugin/common/MethodChannel';
import Log from '../../../util/Log';
import DartExecutor from '../dart/DartExecutor';
import { common } from '@kit.AbilityKit';
import FlutterManager from '../../ohos/FlutterManager';

export default class NavigationChannel {
  private static TAG = "NavigationChannel";
  private channel: MethodChannel;

  constructor(dartExecutor: DartExecutor, context?: common.Context) {
    this.channel = new MethodChannel(dartExecutor, "flutter/navigation", JSONMethodCodec.INSTANCE);
    // Provide a default handler that returns an empty response to any messages
    // on this channel.
    this.channel.setMethodCallHandler(new NavigationCallback(dartExecutor, context));
  }

  setInitialRoute(initialRoute: string): void {
    Log.i(NavigationChannel.TAG, "Sending message to set initial route to '" + initialRoute + "'");
    this.channel.invokeMethod("setInitialRoute", initialRoute);
  }

  pushRoute(route: string): void {
    Log.i(NavigationChannel.TAG, "Sending message to push route '" + route + "'");
    this.channel.invokeMethod("pushRoute", route);
  }

  pushRouteInformation(route: string): void {
    Log.i(NavigationChannel.TAG, "Sending message to push route information '" + route + "'");
    this.channel.invokeMethod("pushRouteInformation", new Map().set("location", route));
  }

  popRoute(): void {
    Log.i(NavigationChannel.TAG, "Sending message to pop route.");
    this.channel.invokeMethod("popRoute", null);
  }

  setMethodCallHandler(handler: MethodCallHandler) {
    this.channel.setMethodCallHandler(handler);
  }
}

class NavigationCallback implements MethodCallHandler {
  private static TAG = "NavigationChannel";
  private dartExecutor: DartExecutor;
  private context?: common.Context;

  constructor(dartExecutor: DartExecutor, context?: common.Context) {
    this.dartExecutor = dartExecutor;
    this.context = context;
  }

  onMethodCall(call: MethodCall, result: MethodResult) {
    if (this.dartExecutor == null || this.dartExecutor.flutterNapi == null) {
      Log.e(NavigationCallback.TAG, "dartExecutor or flutterNapi is null, cancel OHOS page change notification");
      result.success(null);
      return;
    }

    // Skip notification if context is not provided
    if (this.context == null) {
      Log.e(NavigationCallback.TAG, "context is not provided, skip OHOS page change notification");
      result.success(null);
      return;
    }

    const argsMap = call.args as Map<string, string>;
    const currentUri: string = argsMap.get('uri') ?? '';
    const currentUriLen: number = currentUri.length;

    // Dynamically get windowId
    const windowId: number = FlutterManager.getInstance().getWindowId(this.context);
    if (windowId == 0) {
      Log.e(NavigationCallback.TAG, "Failed to get windowId, skip OHOS page change notification, uri: " + currentUri);
      result.success(null);
      return;
    }

    const notifyResult = this.dartExecutor.flutterNapi.NotifyPageChanged(currentUri, currentUriLen, windowId);
    // Return value: 0 means success, non-zero means error
    if (notifyResult == 0) {
      Log.i(NavigationCallback.TAG, "NotifyPageChanged success, uri: " + currentUri + ", windowId: " + windowId);
    } else {
      Log.e(NavigationCallback.TAG, "NotifyPageChanged failed, uri: " + currentUri + ", windowId: " + windowId + ", result: " + notifyResult);
    }

    result.success(null);
  }
}