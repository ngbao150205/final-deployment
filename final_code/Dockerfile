# Stage 1: Build & Dependencies
FROM node:20-alpine AS builder
WORKDIR /app

# Tận dụng Layer Caching
COPY package*.json ./
# Cài đặt strict dependencies, bỏ qua gói dev
RUN npm ci --omit=dev

# Stage 2: Production Runtime
FROM node:20-alpine AS runner
WORKDIR /app

# Đặt biến môi trường Production để Node.js chạy mượt hơn
ENV NODE_ENV=production

# Thiết lập user non-root (Bảo mật - Chống leo thang đặc quyền)
USER node

# Chỉ lấy node_modules sạch từ stage builder sang, đảm bảo quyền sở hữu của user node
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
# Copy mã nguồn dự án vào
COPY --chown=node:node . .

EXPOSE 3000
CMD ["node", "main.js"]