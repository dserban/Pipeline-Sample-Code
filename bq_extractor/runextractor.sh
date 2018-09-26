# DAY_OF_DATA_CAPTURE=2018-09-18 SRC_BQ_DATASET=92806566 DEST_BQ_DATASET=bq_avro_morphl DEST_GCS_BUCKET=bq_avro_morphl BQ_AVRO_HDFS_DIR=bq_avro docker run --rm --net host -v /opt/secrets:/opt/secrets:ro -v /opt/samplecode:/opt/samplecode:ro -v /opt/landing:/opt/landing -e DAY_OF_DATA_CAPTURE -e SRC_BQ_DATASET -e DEST_GCS_BUCKET -e BQ_AVRO_HDFS_DIR -e KEY_FILE_LOCATION -e ENVIRONMENT_TYPE -e MORPHL_SERVER_IP_ADDRESS -it pysparkcontainer bash

DATE_FROM=$(cut -d'|' -f1 /opt/secrets/pipe_delimited_date_range.txt)
DATE_TO=$(cut -d'|' -f2 /opt/secrets/pipe_delimited_date_range.txt)
[[ "${DAY_OF_DATA_CAPTURE}" < "${DATE_FROM}" || "${DAY_OF_DATA_CAPTURE}" > "${DATE_TO}" ]] && exit 0
GCP_PROJECT_ID=$(jq -r '.project_id' ${KEY_FILE_LOCATION})
HDFS_PORT=9000
FQ_BQ_AVRO_HDFS_DIR=hdfs://${MORPHL_SERVER_IP_ADDRESS}:${HDFS_PORT}/${BQ_AVRO_HDFS_DIR}
GA_SESSIONS_DATA_ID=ga_sessions_$(echo ${DAY_OF_DATA_CAPTURE} | sed 's/-//g')
WEBSITE_URL=$(</opt/secrets/website_url.txt)
gcloud config set project ${GCP_PROJECT_ID}
gcloud auth activate-service-account --key-file=${KEY_FILE_LOCATION}
bq ls &>/dev/null
bq extract --destination_format=AVRO ${SRC_BQ_DATASET}.${GA_SESSIONS_DATA_ID} gs://${DEST_GCS_BUCKET}/${GA_SESSIONS_DATA_ID}.avro
gsutil cp gs://${DEST_GCS_BUCKET}/${GA_SESSIONS_DATA_ID}.avro /opt/landing/
hdfs dfs -mkdir -p ${FQ_BQ_AVRO_HDFS_DIR}
hdfs dfs -copyFromLocal -f /opt/landing/${GA_SESSIONS_DATA_ID}.avro ${FQ_BQ_AVRO_HDFS_DIR}/${GA_SESSIONS_DATA_ID}.avro
# rm /opt/landing/${GA_SESSIONS_DATA_ID}.avro
