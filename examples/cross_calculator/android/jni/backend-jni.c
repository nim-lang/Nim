/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
#include <android/log.h>
#include <string.h>
#include "backend-jni.h"
#include "backend.h"

#define TAG		"backend-jni.c"

jint JNICALL Java_com_github_nimrod_crosscalculator_CrossCalculator_myAdd
	(JNIEnv *env, jobject thiz, jint a, jint b)
{
	char buf[256];
	const jint ret = myAdd(a, b);
	// Using logging from inside the native bridge to log-debug.
	sprintf(buf, "a %d + b %d = ret %d", a, b, ret);
	__android_log_write(ANDROID_LOG_DEBUG, TAG, buf);
	return ret;
}

void JNICALL Java_com_github_nimrod_crosscalculator_CrossCalculator_initNimMain
	(JNIEnv *env, jclass thiz)
{
	NimMain();
	__android_log_write(ANDROID_LOG_DEBUG, TAG, "Nimrod initialised");
}

// vim:tabstop=2 shiftwidth=2 syntax=c
