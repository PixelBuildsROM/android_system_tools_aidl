#
# Copyright (C) 2015 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

aidl_cflags := -Wall -Wextra -Werror

# This tool is prebuilt if we're doing an app-only build.
ifeq ($(TARGET_BUILD_APPS)$(filter true,$(TARGET_BUILD_PDK)),)

aidl_static_libraries := libbase libcutils

# Logic shared between aidl and its unittests
include $(CLEAR_VARS)
LOCAL_MODULE := libaidl-common
LOCAL_MODULE_HOST_OS := darwin linux windows

LOCAL_C_INCLUDES := external/gtest/include
LOCAL_CLANG_CFLAGS := $(aidl_cflags)
# Tragically, the code is riddled with unused parameters.
LOCAL_CLANG_CFLAGS += -Wno-unused-parameter
# yacc dumps a lot of code *just in case*.
LOCAL_CLANG_CFLAGS += -Wno-unused-function
LOCAL_CLANG_CFLAGS += -Wno-unneeded-internal-declaration
# yacc is a tool from a more civilized age.
LOCAL_CLANG_CFLAGS += -Wno-deprecated-register
# yacc also has a habit of using char* over const char*.
LOCAL_CLANG_CFLAGS += -Wno-writable-strings
LOCAL_STATIC_LIBRARIES := $(aidl_static_libraries)

LOCAL_SRC_FILES := \
    aidl.cpp \
    aidl_language.cpp \
    aidl_language_l.l \
    aidl_language_y.y \
    ast_cpp.cpp \
    ast_java.cpp \
    code_writer.cpp \
    generate_cpp.cpp \
    generate_java.cpp \
    generate_java_binder.cpp \
    import_resolver.cpp \
    io_delegate.cpp \
    options.cpp \
    type_cpp.cpp \
    type_java.cpp \
    type_namespace.cpp \

include $(BUILD_HOST_STATIC_LIBRARY)


# aidl executable
include $(CLEAR_VARS)
LOCAL_MODULE := aidl

LOCAL_MODULE_HOST_OS := darwin linux windows
LOCAL_CFLAGS := $(aidl_cflags)
LOCAL_C_INCLUDES := external/gtest/include
LOCAL_SRC_FILES := main_java.cpp
LOCAL_STATIC_LIBRARIES := libaidl-common $(aidl_static_libraries)
include $(BUILD_HOST_EXECUTABLE)

# aidl-cpp executable
include $(CLEAR_VARS)
LOCAL_MODULE := aidl-cpp

LOCAL_MODULE_HOST_OS := darwin linux windows
LOCAL_CFLAGS := $(aidl_cflags)
LOCAL_C_INCLUDES := external/gtest/include
LOCAL_SRC_FILES := main_cpp.cpp
LOCAL_STATIC_LIBRARIES := libaidl-common $(aidl_static_libraries)
include $(BUILD_HOST_EXECUTABLE)


# TODO(wiley) Compile these for mac as well after b/22771504
ifeq ($(HOST_OS),linux)
# Unit tests
include $(CLEAR_VARS)
LOCAL_MODULE := aidl_unittests

LOCAL_CFLAGS := $(aidl_cflags) -g -DUNIT_TEST
# Tragically, the code is riddled with unused parameters.
LOCAL_CLANG_CFLAGS := -Wno-unused-parameter
LOCAL_SRC_FILES := \
    aidl_unittest.cpp \
    ast_cpp_unittest.cpp \
    ast_java_unittest.cpp \
    generate_cpp_unittest.cpp \
    options_unittest.cpp \
    tests/end_to_end_tests.cpp \
    tests/fake_io_delegate.cpp \
    tests/main.cpp \
    tests/test_data_example_interface.cpp \
    tests/test_data_ping_responder.cpp \
    tests/test_util.cpp \
    type_cpp_unittest.cpp \
    type_java_unittest.cpp \

LOCAL_SHARED_LIBRARIES := \
    libchrome-host \

LOCAL_STATIC_LIBRARIES := \
    libaidl-common \
    $(aidl_static_libraries) \
    libgmock_host \
    libgtest_host \

LOCAL_LDLIBS_linux := -lrt

include $(BUILD_HOST_NATIVE_TEST)
endif # HOST_OS == linux

endif # No TARGET_BUILD_APPS or TARGET_BUILD_PDK

include $(CLEAR_VARS)
LOCAL_MODULE := aidl_test_service
LOCAL_SRC_FILES := \
    tests/android/aidl/tests/ITestService.aidl \
    tests/aidl_test_service.cpp
LOCAL_SHARED_LIBRARIES := \
    libbinder \
    liblog \
    libutils
LOCAL_CFLAGS := $(aidl_cflags) -Wunused-parameter
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)
LOCAL_MODULE := aidl_test_client
LOCAL_SRC_FILES := \
    tests/android/aidl/tests/ITestService.aidl \
    tests/aidl_test_client.cpp
LOCAL_SHARED_LIBRARIES := \
    libbinder \
    liblog \
    libutils
LOCAL_CFLAGS := $(aidl_cflags) -Wunused-parameter
include $(BUILD_EXECUTABLE)


# aidl on its own doesn't need the framework, but testing native/java
# compatibility introduces java dependencies.
ifndef BRILLO

include $(CLEAR_VARS)
LOCAL_PACKAGE_NAME := aidl_test_services
LOCAL_DEX_PREOPT := false
LOCAL_CERTIFICATE := platform
LOCAL_MANIFEST_FILE := tests/java_app/AndroidManifest.xml
LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/tests/java_app/resources
LOCAL_SRC_FILES := \
    tests/android/aidl/tests/ITestService.aidl \
    tests/java_app/src/android/aidl/tests/TestServiceClient.java
include $(BUILD_PACKAGE)

endif  # not defined BRILLO
