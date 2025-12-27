import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AppMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const AppMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    return MarkdownBody(
      data: data,
      selectable: selectable,
      sizedImageBuilder: (config) {
        final uri = config.uri;
        final width = config.width;
        final height = config.height;

        // Handle network images with caching
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: uri.toString(),
                width: width,
                height: height,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  height: height ?? 200,
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: height ?? 200,
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }
        // Handle asset images
        if (uri.scheme == 'asset') {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                uri.path,
                width: width,
                height: height,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: height ?? 200,
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }
        // Fallback for other URIs
        return const SizedBox.shrink();
      },
      styleSheet: MarkdownStyleSheet(
        // Base Typography
        p: const TextStyle(
          fontSize: 16.5,
          height: 1.8,
          color: Color(0xFF433D39),
          letterSpacing: 0.2,
        ),
        
        // Headings - Blog Style
        h1: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF433D39),
          height: 1.4,
          letterSpacing: -0.5,
        ),
        h1Padding: const EdgeInsets.only(top: 32, bottom: 16),
        
        // H2 with Decoration (Left Border + Background)
        h2: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF433D39),
          height: 1.4,
        ),
        h2Padding: const EdgeInsets.only(top: 32, bottom: 16),
        
        h3: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF433D39),
          height: 1.4,
        ),
        h3Padding: const EdgeInsets.only(top: 24, bottom: 12),

        // Lists
        listBullet: TextStyle(
          fontSize: 16.5,
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        listIndent: 24,
        
        // Quotes
        blockquote: const TextStyle(
          fontSize: 15.5,
          height: 1.6,
          color: Color(0xFF6D6D6D),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: const Color(0xFFE5DCD5).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: primaryColor,
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        
        // Code
        code: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          backgroundColor: Colors.transparent, // Handled by decoration
          color: Color(0xFFD63384), // Pinkish for inline code
          fontWeight: FontWeight.w500,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF2D2D2D), // Dark theme for code blocks
          borderRadius: BorderRadius.circular(12),
        ),
        codeblockPadding: const EdgeInsets.all(16),
        
        // Tables
        tableBorder: TableBorder.all(
          color: const Color(0xFFE5DCD5),
          width: 1,
        ),
        tableHead: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF433D39),
        ),
        tableBody: const TextStyle(
          fontSize: 15,
          color: Color(0xFF433D39),
        ),
        tableHeadAlign: TextAlign.center,
        tablePadding: const EdgeInsets.all(12),
        
        // Links
        a: TextStyle(
          color: primaryColor,
          decoration: TextDecoration.underline,
          decorationColor: primaryColor.withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
        
        // Emphasis
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF433D39),
        ),
        
        // Divider
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF433D39).withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
