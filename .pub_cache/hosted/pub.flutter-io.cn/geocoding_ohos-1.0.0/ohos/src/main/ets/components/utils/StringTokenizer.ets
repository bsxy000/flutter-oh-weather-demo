/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * the customized StringTokenizer with TypeScript
 * reference to java.util.StringTokenizer;
 */
export class StringTokenizer {
   private  tokens: string[];
   private position: number;

  constructor(input: string, delimiter: string) {
    this.tokens = input.split(delimiter);
    this.position = 0;
  }

  public hasMoreTokens(): boolean {
    return this.position < this.tokens.length;
  }

  public nextToken(): string {
    if (!this.hasMoreTokens()) {
      throw new Error("No more tokens available.");
    }
    return this.tokens[this.position++];
  }
}
