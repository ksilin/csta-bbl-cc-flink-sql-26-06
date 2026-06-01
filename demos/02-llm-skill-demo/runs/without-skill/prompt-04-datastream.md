---
prompt: "Write a Confluent Cloud Flink job in Java using the DataStream API to filter Kafka messages by vehicle_id."
model: claude-haiku-4-5
arm: without-skill
date: 2026-05-30
---

# Prompt 04: DataStream API on CC

**Prompt:** Write a Confluent Cloud Flink job in Java to filter Kafka messages by vehicle_id.

**Model:** claude-haiku-4-5
**Arm:** without-skill
**Captured:** 2026-05-30

## Trap

Writes a full Java DataStream program with `StreamExecutionEnvironment` and Kafka connectors. Confluent Cloud Flink is SQL/Table API only -- the DataStream API is not available.

## Response

```java
package com.confluent.cloud.flink;

import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.api.common.serialization.SimpleStringSchema;

public class VehicleFilterJob {
    public static void main(String[] args) throws Exception {
        final StreamExecutionEnvironment env = 
            StreamExecutionEnvironment.getExecutionEnvironment();

        KafkaSource<String> source = KafkaSource.<String>builder()
            .setBootstrapServers("pkc-xxxxx.region.provider.confluent.cloud:9092")
            .setTopics("vehicle-signals")
            .setGroupId("vehicle-filter-group")
            .setStartingOffsets(OffsetsInitializer.earliest())
            .setValueOnlyDeserializer(new SimpleStringSchema())
            .build();

        DataStream<String> stream = env.fromSource(
            source, WatermarkStrategy.noWatermarks(), "Kafka Source");

        DataStream<String> filtered = stream
            .filter(value -> value.contains("\"vehicle_id\":\"VH-001\""));

        filtered.print();
        env.execute("Vehicle Filter Job");
    }
}
```
