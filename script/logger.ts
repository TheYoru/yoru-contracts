import { default as pLog } from "pino"

export const logger = pLog({
    transport: {
        target: "pino-pretty",
        levelKey: "trace",
        levelFirst: true,
        translateTime: true,
        ignore: "pid,hostname",
        singleLine: true,
    },
})
