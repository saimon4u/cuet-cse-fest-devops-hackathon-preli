FROM node:18-alpine AS builder

RUN addgroup -g 1001 -S nodejs && adduser -S backend -u 1001

WORKDIR /app

COPY package*.json ./

RUN npm ci --production

COPY . .

RUN chown -R backend:nodejs /app

USER backend

EXPOSE 5921

CMD ["npm", "start"]

