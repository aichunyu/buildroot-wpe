################################################################################
#
# gst1-bcm
#
################################################################################
GST1_BCM_VERSION = 726bbcf894a59aefdeee0a9179eb4927d7907bb3
GST1_BCM_SITE = git@github.com:Metrological/gstreamer-plugins-soc.git
GST1_BCM_SITE_METHOD = git
GST1_BCM_LICENSE = PROPRIETARY
GST1_BCM_DEPENDENCIES = gstreamer1 gst1-plugins-base bcm-refsw libcurl mpg123

GST1_BCM_AUTORECONF = YES

GST1_BCM_CONF_ENV += \
	$(BCM_REFSW_MAKE_ENV) \
	GSTREAMER_REFSW_SERVER_NXCLIENT_SUPPORT=y \
	PKG_CONFIG_SYSROOT_DIR=$(STAGING_DIR)

GST1_BCM_MAKE_ENV += \
	$(BCM_REFSW_MAKE_ENV) \
	PKG_CONFIG_SYSROOT_DIR=$(STAGING_DIR)

GST1_BCM_MAKE_OPTS += "\
	CFLAGS+=${CFLAGS} \
		-std=c99 \
		-I${BCM_REWSW_BIN}/include \
		-I${BCM_REFSW_DIR}/BSEAV/api/include \
		-I${BCM_REFSW_DIR}/BSEAV/lib/media/"

GST1_BCM_CONF_OPTS = \
	--enable-gstreamer1  \
	--enable-shared \
	--with-pic \
	--disable-static \
	--enable-systemclock \
	--disable-avi \
	--disable-flv \
	--disable-httpsrc \
	--disable-ivfparse \
	--disable-matroska \
	--disable-mp3swdecode \
	--disable-mp4demux \
	--disable-pcmsink \
	--disable-pesdemux \
	--disable-playback \
	--disable-qtdemux \
	--disable-transcode \
	--disable-tsdemux \
	--disable-tsparse \
	--disable-playersinkbin \
	--disable-gfxsink

ifeq ($(BR2_PACKAGE_GST1_BCM_AUDFILTER),y)
GST1_BCM_CONF_OPTS += --enable-audfilter
else
GST1_BCM_CONF_OPTS += --disable-audfilter
endif

ifeq ($(BR2_PACKAGE_GST1_BCM_AUDIODECODE),y)
GST1_BCM_CONF_OPTS += --enable-audiodecode
else
GST1_BCM_CONF_OPTS += --disable-audiodecode
endif

ifeq ($(BR2_PACKAGE_GST1_BCM_AUDIOSINK),y)
GST1_BCM_CONF_OPTS += --enable-audiosink
else
GST1_BCM_CONF_OPTS += --disable-audiosink
endif

ifeq ($(BR2_PACKAGE_GST1_BCM_VIDEODECODE),y)
GST1_BCM_CONF_OPTS += --enable-videodecode
else
GST1_BCM_CONF_OPTS += --disable-videodecode
endif

ifeq ($(BR2_PACKAGE_GST1_BCM_VIDEOSINK),y)
GST1_BCM_CONF_OPTS += --enable-videosink
else
GST1_BCM_CONF_OPTS += --disable-videosink
endif

ifeq ($(BR2_PACKAGE_GST1_BCM_VIDFILTER),y)
GST1_BCM_CONF_OPTS += --enable-vidfilter
else
GST1_BCM_CONF_OPTS += --disable-vidfilter
endif

$(eval $(autotools-package))
